{-# LANGUAGE DataKinds #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE TemplateHaskell #-}

module Server (IO, main, Account, Profile, LoginResponse, Api) where

--------------------------------------------------------------------------------
-- SECTION: Imports
--------------------------------------------------------------------------------

import Basement.Compat.Base (Int64)
import Control.Monad.IO.Class (liftIO)
import Control.Monad.Reader (ReaderT, ask, runReaderT)
import Data.Aeson (Result (..), fromJSON, toJSON)
import Data.ByteString (ByteString)
import Data.ByteString.Lazy.Char8 qualified as BL8
import Data.Int (Int64)
import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe)
import Data.Password.Argon2 (Argon2, Password, PasswordCheck (..), PasswordHash (..), checkPassword, hashPassword, mkPassword)
import Data.Text (Text, length, null, pack, unpack)
import Data.Time.Clock (NominalDiffTime, UTCTime, getCurrentTime)
import Data.Time.Clock.POSIX (utcTimeToPOSIXSeconds)
import Data.Vector qualified as V
import Distribution.Simple.Hpc (Way (Prof))
import Elm.Derive (defaultOptions, deriveBoth)
import GHC.Generics
import Hasql.Connection.Setting qualified as ConnectionSetting
import Hasql.Connection.Setting.Connection qualified as ConnectionSettingConnection
import Hasql.Pool (Pool, UsageError (SessionUsageError), acquire, use)
import Hasql.Pool.Config qualified as PoolConfig
import Hasql.Session (CommandError (..), ResultError (..), Session, SessionError (..))
import Hasql.Session qualified as Session
import Hasql.Statement (Statement (..))
import Hasql.TH qualified as TH
import Network.Wai (Application)
import Network.Wai.Handler.Warp (defaultSettings, runSettings, setBeforeMainLoop, setPort)
import Network.Wai.Middleware.Cors (CorsResourcePolicy (corsMethods, corsRequestHeaders), cors, simpleCorsResourcePolicy)
import Servant
import Servant (Handler, ServerT, err500, hoistServer, serve, throwError, (:<|>) (..))
import Servant.API (Capture, Get, JSON, (:>))
import System.Environment (getEnv, lookupEnv)
import System.IO (hPutStrLn, stderr)
import Web.JWT (stringOrURIToText)
import Web.JWT qualified as JWT

--------------------------------------------------------------------------------
-- SECTION: Types and API
--------------------------------------------------------------------------------

data Account = Account
  { accountId :: Maybe Int64,
    accountName :: Text,
    accountPassword :: Text,
    accountProfile :: Maybe Profile
  }
  deriving (Eq, Show, Generic)

data Profile = Profile
  { profileName :: Text,
    profileCreatedAt :: UTCTime
  }
  deriving (Eq, Show, Generic)

data LoginResponse = LoginResponse
  { token :: Text,
    responseProfile :: Maybe Profile
  }
  deriving (Eq, Show, Generic)

-- Compile-time Elm/JSON derives
$(deriveBoth defaultOptions ''Profile)
$(deriveBoth defaultOptions ''Account)
$(deriveBoth defaultOptions ''LoginResponse)

type Api =
  "register" :> ReqBody '[JSON] Account :> Post '[JSON] LoginResponse
    :<|> "login" :> ReqBody '[JSON] Account :> Post '[JSON] LoginResponse
    :<|> "profile" :> Header "Authorization" Text :> Get '[JSON] Profile

api :: Proxy Api
api = Proxy

--------------------------------------------------------------------------------
-- SECTION: config
--------------------------------------------------------------------------------

data Env = Env
  { envConfig :: Config,
    envPool :: Pool
  }

data Config = Config
  { cfgPgHost :: Text,
    cfgPgPoolSize :: Int,
    cfgPort :: Int,
    cfgJwtSecret :: Text
  }
  deriving (Show, Eq)

defaultPort :: Int
defaultPort = 1337

defaultPoolSize :: Int
defaultPoolSize = 10

defaultJwtExpiry :: NominalDiffTime
defaultJwtExpiry = 3600

readConfig :: IO Config
readConfig = do
  host <- pack <$> getEnv "PGHOST"
  mPoolSz <- lookupEnv "PGPOOLSIZE"
  jwtSecret <- pack <$> getEnv "JWT_SECRET"
  let poolSz = maybe defaultPoolSize read mPoolSz
  pure Config {cfgPgHost = host, cfgPgPoolSize = poolSz, cfgPort = defaultPort, cfgJwtSecret = jwtSecret}

--------------------------------------------------------------------------------
-- SECTION: DB
--------------------------------------------------------------------------------

withPool :: Config -> (Pool -> IO a) -> IO a
withPool cfg action = do
  let pstr = "host=" <> cfgPgHost cfg <> " dbname=app user=app port=5432"
      poolConfig =
        PoolConfig.settings
          [ PoolConfig.size (cfgPgPoolSize cfg),
            PoolConfig.staticConnectionSettings [ConnectionSetting.connection $ ConnectionSettingConnection.string pstr]
          ]
  pool <- acquire poolConfig
  action pool

accountRegisterSession :: Account -> Session Account
accountRegisterSession (Account _ email password mProfile) = do
  hashed <- hashPassword $ mkPassword password
  aid <-
    Session.statement
      (email, unPasswordHash hashed)
      [TH.singletonStatement|
      INSERT INTO account (name, password)
      VALUES ($1 :: text, $2 :: text)
      RETURNING id :: int8
    |]
  let profileName' = maybe email profileName mProfile
  (pName, pCreatedAt) <-
    Session.statement
      (aid, profileName')
      [TH.singletonStatement|
      INSERT INTO profile (account_id, name)
      VALUES ($1 :: int8, $2 :: text)
      RETURNING name :: text, created_at :: timestamptz
    |]
  pure $
    Account
      { accountId = Just aid,
        accountName = email,
        accountPassword = "",
        accountProfile = Just (Profile pName pCreatedAt)
      }

accountLoginSession :: Account -> Session (Maybe Account)
accountLoginSession acc =
  Session.statement
    (accountName acc)
    [TH.maybeStatement|
      SELECT a.id :: int8, a.name :: text, a.password :: text,
             p.name :: text?, p.created_at :: timestamptz?
      FROM account a
      LEFT JOIN profile p ON p.account_id = a.id
      WHERE a.name = $1 :: text
    |]
    >>= \case
      Nothing -> pure Nothing
      Just (aid, name', dbHash, mProfName, mProfCreatedAt) ->
        pure $
          Just $
            Account
              { accountId = Just aid,
                accountName = name',
                accountPassword = dbHash,
                accountProfile = Profile <$> mProfName <*> mProfCreatedAt
              }

profileSession :: Text -> Session (Maybe Profile)
profileSession accountName = do
  Session.statement
    accountName
    [TH.maybeStatement|
      SELECT name :: text, created_at :: timestamptz FROM profile WHERE account_id = (SELECT id FROM account WHERE name = $1 :: text)
    |]
    >>= \case
      Nothing -> pure Nothing
      Just (name, createdAt) ->
        pure $ Just $ Profile name createdAt

logDbError :: UsageError -> App ()
logDbError err = liftIO $ hPutStrLn stderr ("DB UsageError: " ++ show err)

-- | Optionally handle UsageError specially, e.g. for unique constraint
runDbSession :: (Pool -> IO (Either UsageError a)) -> (a -> App b) -> Maybe (UsageError -> App b) -> App b
runDbSession action onSuccess mErrHandler = do
  env <- ask
  let pool = envPool env
  result <- liftIO $ action pool
  case result of
    Left err -> do
      logDbError err
      case mErrHandler of
        Just handle -> handle err
        Nothing -> throwError err500
    Right val -> onSuccess val

--------------------------------------------------------------------------------
-- SECTION: AppM and Handlers
---------------------------------------------------------------------------------

type App = ReaderT Env Handler

runApp :: Env -> App a -> Handler a
runApp env app = runReaderT app env

validatePassword :: Text -> Text -> Bool
validatePassword input dbHash =
  case checkPassword (mkPassword input) (PasswordHash dbHash) of
    PasswordCheckSuccess -> True
    _ -> False

-- Build JWT claims for a user (pure)
mkJWTClaims :: Text -> JWT.NumericDate -> Maybe JWT.NumericDate -> JWT.JWTClaimsSet
mkJWTClaims accountName iatVal mExpVal =
  JWT.JWTClaimsSet
    { JWT.sub = JWT.stringOrURI accountName,
      JWT.iat = Just iatVal,
      JWT.exp = mExpVal,
      JWT.nbf = Nothing,
      JWT.iss = Nothing,
      JWT.aud = Nothing,
      JWT.jti = Nothing,
      JWT.unregisteredClaims = JWT.ClaimsMap $ Map.fromList []
    }

-- | Updated token generation to include expiry
mkAuthToken :: Text -> Text -> JWT.NumericDate -> Maybe JWT.NumericDate -> Text
mkAuthToken secret accountName iatVal mExpVal =
  pureJWTToken secret (mkJWTClaims accountName iatVal mExpVal)

mkAuthResponse :: Text -> Text -> JWT.NumericDate -> Maybe JWT.NumericDate -> LoginResponse
mkAuthResponse secret accountName iatVal mExpVal =
  pureLoginResponse (mkAuthToken secret accountName iatVal mExpVal)

mkLoginResponse :: Text -> Maybe Profile -> LoginResponse
mkLoginResponse token profile = LoginResponse {token = token, responseProfile = profile}

pureJWTToken :: Text -> JWT.JWTClaimsSet -> Text
pureJWTToken secret claims = JWT.encodeSigned (JWT.hmacSecret secret) mempty claims

pureLoginResponse :: Text -> LoginResponse
pureLoginResponse token = LoginResponse {token = token, responseProfile = Nothing}

-- | Validate account registration input
validateRegisterInput :: Account -> Either Text Account
validateRegisterInput acc
  | Data.Text.null (accountName acc) = Left "Missing or empty accountName"
  | Data.Text.null (accountPassword acc) = Left "Missing or empty accountPassword"
  | Data.Text.length (accountPassword acc) < 8 = Left "Password must be at least 8 characters"
  | otherwise = Right acc

register :: Account -> App LoginResponse
register account =
  case validateRegisterInput account of
    Left errMsg -> throwError Servant.err400 {Servant.errBody = BL8.pack (unpack errMsg)}
    Right validAcc ->
      runDbSession
        (\pool -> use pool (accountRegisterSession validAcc))
        ( \account -> do
            env <- ask
            let secret = cfgJwtSecret (envConfig env)
            now <- liftIO getCurrentTime
            case JWT.numericDate (utcTimeToPOSIXSeconds now) of
              Just iatVal -> do
                let expiry = JWT.numericDate (utcTimeToPOSIXSeconds now + 3600) -- 1 hour
                pure $ mkAuthResponse secret (accountName validAcc) iatVal expiry
              Nothing -> throwError err500 {Servant.errBody = BL8.pack "Failed to generate JWT iat"}
        )
        (Just handleRegisterDbError)

-- | Custom handler for register DB errors
handleRegisterDbError :: UsageError -> App LoginResponse
handleRegisterDbError err =
  case err of
    SessionUsageError (QueryError _ _ (ResultError (Session.ServerError code _ _ _ _))) ->
      if code == "23505"
        then throwError err409 {Servant.errBody = BL8.pack "Username already exists"}
        else throwError err500
    _ -> throwError err500

-- | Dedicated session for login
-- | Validate account login input
validateLoginInput :: Account -> Either Text Account
validateLoginInput acc
  | Data.Text.null (accountName acc) = Left "Missing or empty accountName"
  | Data.Text.null (accountPassword acc) = Left "Missing or empty accountPassword"
  | otherwise = Right acc

login :: Account -> App LoginResponse
login account =
  case validateLoginInput account of
    Left errMsg -> throwError Servant.err400 {Servant.errBody = BL8.pack (unpack errMsg)}
    Right validAcc ->
      runDbSession
        (\pool -> use pool (accountLoginSession validAcc))
        ( \res -> case res of
            Nothing -> throwError err401 {Servant.errBody = BL8.pack "Invalid login or password"}
            Just dbAccount ->
              if validatePassword (accountPassword validAcc) (accountPassword dbAccount)
                then do
                  env <- ask
                  let secret = cfgJwtSecret (envConfig env)
                  now <- liftIO getCurrentTime
                  case JWT.numericDate (utcTimeToPOSIXSeconds now) of
                    Just iatVal -> do
                      let expiry = JWT.numericDate (utcTimeToPOSIXSeconds now + defaultJwtExpiry) -- 1 hour
                      pure $ mkAuthResponse secret (accountName validAcc) iatVal expiry
                    Nothing -> throwError err500 {Servant.errBody = BL8.pack "Failed to generate JWT iat"}
                else throwError err401 {Servant.errBody = BL8.pack "Invalid login or password"}
        )
        Nothing

profile :: Maybe Text -> App Profile
profile auth = do
  env <- ask
  let secret = cfgJwtSecret (envConfig env)
  case auth of
    Nothing -> throwError err401 {Servant.errBody = "Missing Authorization header"}
    Just authHeader ->
      let authStr = unpack authHeader
          token = case words authStr of
            ["Bearer", t] -> t
            [t] -> t -- fallback: accept plain token
            _ -> authStr
       in case JWT.decodeAndVerifySignature (JWT.toVerify (JWT.hmacSecret secret)) (pack token) of
            Nothing -> throwError err401 {Servant.errBody = "Invalid or expired token"}
            Just jwt -> do
              aName <- case stringOrURIToText <$> JWT.sub (JWT.claims jwt) of
                Nothing -> throwError err401 {Servant.errBody = ""}
                Just n -> pure n
              runDbSession
                (\pool -> use pool (profileSession aName))
                ( \res -> case res of
                    Nothing -> throwError err401 {Servant.errBody = BL8.pack "Invalid login or password"}
                    Just profile -> pure profile
                )
                Nothing

server :: ServerT Api App
server = register :<|> login :<|> profile

-- | Handler for getting the profile of the currently authenticated user.
mkApp :: Env -> IO Application
mkApp env = do
  let apiApp = serve api (hoistServer api (runApp env) server)
  pure $
    cors
      ( const $
          Just
            simpleCorsResourcePolicy
              { corsRequestHeaders = ["Content-Type", "Authorization"],
                corsMethods = ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
              }
      )
      apiApp

--------------------------------------------------------------------------------
-- SECTION: Main
--------------------------------------------------------------------------------

main :: IO ()
main = do
  config <- readConfig
  let port = cfgPort config
      settings =
        setPort port $
          setBeforeMainLoop (hPutStrLn stderr ("listening on port " ++ show port)) $
            defaultSettings
  withPool config $ \pool -> do
    let env = Env {envConfig = config, envPool = pool}
    app <- mkApp env
    runSettings settings app
