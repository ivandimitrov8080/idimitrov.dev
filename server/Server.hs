{-# LANGUAGE DataKinds #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE TemplateHaskell #-}

module Server (main, Account, Profile, LoginResponse, Api) where

import Config
import Control.Monad.IO.Class (liftIO)
import Control.Monad.Reader (ReaderT, ask, runReaderT)
import Data.ByteString.Lazy.Char8 qualified as BL8
import Data.Int (Int64)
import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe)
import Data.Password.Argon2 (PasswordCheck (..), PasswordHash (..), checkPassword, hashPassword, mkPassword)
import Data.Text (Text, length, null, pack, splitOn, strip, unpack)
import Data.Time.Clock (NominalDiffTime, UTCTime, getCurrentTime)
import Data.Time.Clock.POSIX (utcTimeToPOSIXSeconds)
import Elm.Derive (defaultOptions, deriveBoth)
import GHC.Generics (Generic)
import Hasql.Connection.Setting qualified as ConnectionSetting
import Hasql.Connection.Setting.Connection qualified as ConnectionSettingConnection
import Hasql.Pool (Pool, UsageError (SessionUsageError), acquire, use)
import Hasql.Pool.Config qualified as PoolConfig
import Hasql.Session (CommandError (..), ResultError (..), Session, SessionError (..))
import Hasql.Session qualified as Session
import Hasql.TH qualified as TH
import Network.Wai (Application)
import Network.Wai.Handler.Warp (defaultSettings, runSettings, setBeforeMainLoop, setPort)
import Network.Wai.Middleware.Cors (CorsResourcePolicy (corsMethods, corsOrigins, corsRequestHeaders), cors, simpleCorsResourcePolicy)
import Servant (Handler, Proxy (..), Raw, ServerT, err400, err401, err409, err500, errBody, hoistServer, serve, serveDirectoryFileServer, throwError, (:<|>) (..))
import Servant.API (Get, Header, JSON, Post, ReqBody, (:>))
import System.Environment (getEnv, lookupEnv)
import System.IO (hPutStrLn, stderr)
import Text.Read (readMaybe)
import Web.JWT (stringOrURIToText)
import Web.JWT qualified as JWT

data Env = Env
  { envConfig :: Config,
    envPool :: Pool
  }

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

$(deriveBoth defaultOptions ''Profile)
$(deriveBoth defaultOptions ''Account)
$(deriveBoth defaultOptions ''LoginResponse)

type Api =
  "register" :> ReqBody '[JSON] Account :> Post '[JSON] LoginResponse
    :<|> "login" :> ReqBody '[JSON] Account :> Post '[JSON] LoginResponse
    :<|> "profile" :> Header "Authorization" Text :> Get '[JSON] Profile

type AppApi = Api :<|> Raw

api :: Proxy AppApi
api = Proxy

withPool :: Config -> (Pool -> IO a) -> IO a
withPool cfg action = do
  pool <- acquire poolConfig
  action pool
  where
    pstr = "host=" <> cfgPgHost cfg <> " dbname=app user=app port=5432"
    poolConfig =
      PoolConfig.settings
        [ PoolConfig.size (cfgPgPoolSize cfg),
          PoolConfig.staticConnectionSettings [ConnectionSetting.connection $ ConnectionSettingConnection.string pstr]
        ]

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

type App = ReaderT Env Handler

runApp :: Env -> App a -> Handler a
runApp env app = runReaderT app env

validatePassword :: Text -> Text -> Bool
validatePassword input dbHash =
  case checkPassword (mkPassword input) (PasswordHash dbHash) of
    PasswordCheckSuccess -> True
    _ -> False

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

validateRegisterInput :: Account -> Either Text Account
validateRegisterInput acc
  | Data.Text.null (accountName acc) = Left "Missing or empty accountName"
  | Data.Text.null (accountPassword acc) = Left "Missing or empty accountPassword"
  | Data.Text.length (accountPassword acc) < 8 = Left "Password must be at least 8 characters"
  | otherwise = Right acc

register :: Account -> App LoginResponse
register account =
  case validateRegisterInput account of
    Left errMsg -> throwError err400 {errBody = BL8.pack (unpack errMsg)}
    Right validAcc ->
      runDbSession
        (\pool -> use pool (accountRegisterSession validAcc))
        ( \_ -> do
            env <- ask
            now <- liftIO getCurrentTime
            let secret = cfgJwtSecret (envConfig env)
            case JWT.numericDate (utcTimeToPOSIXSeconds now) of
              Just iatVal -> do
                let expiry = JWT.numericDate (utcTimeToPOSIXSeconds now + 3600)
                pure $ mkAuthResponse secret (accountName validAcc) iatVal expiry
              Nothing -> throwError err500 {errBody = BL8.pack "Failed to generate JWT iat"}
        )
        (Just handleRegisterDbError)

handleRegisterDbError :: UsageError -> App LoginResponse
handleRegisterDbError (SessionUsageError (QueryError _ _ (ResultError (Session.ServerError "23505" _ _ _ _)))) =
  throwError err409 {errBody = BL8.pack "Username already exists"}
handleRegisterDbError _ = throwError err500

validateLoginInput :: Account -> Either Text Account
validateLoginInput acc
  | Data.Text.null (accountName acc) = Left "Missing or empty accountName"
  | Data.Text.null (accountPassword acc) = Left "Missing or empty accountPassword"
  | otherwise = Right acc

login :: Account -> App LoginResponse
login account = do
  case validateLoginInput account of
    Left errMsg -> throwError err400 {errBody = BL8.pack (unpack errMsg)}
    Right validAcc ->
      runDbSession
        (\pool -> use pool (accountLoginSession validAcc))
        ( \case
            Nothing -> throwError err401 {errBody = BL8.pack "Invalid login or password"}
            Just dbAccount
              | validatePassword (accountPassword validAcc) (accountPassword dbAccount) -> do
                  env <- ask
                  now <- liftIO getCurrentTime
                  let cfg = envConfig env
                      secret = cfgJwtSecret cfg
                      jwtExpiry = cfgJwtExpiry cfg
                  case JWT.numericDate (utcTimeToPOSIXSeconds now) of
                    Just iatVal -> do
                      let expiry = JWT.numericDate (utcTimeToPOSIXSeconds now + (jwtExpiry))
                      pure $ mkAuthResponse secret (accountName validAcc) iatVal expiry
                    Nothing -> throwError err500 {errBody = BL8.pack "Failed to generate JWT iat"}
              | otherwise -> throwError err401 {errBody = BL8.pack "Invalid login or password"}
        )
        Nothing

-- | Retrieve the profile of the currently authenticated user via JWT
profile :: Maybe Text -> App Profile
profile Nothing = throwError err401 {errBody = "Missing Authorization header"}
profile (Just authHeader) = do
  env <- ask
  let secret = cfgJwtSecret (envConfig env)
  case JWT.decodeAndVerifySignature (JWT.toVerify (JWT.hmacSecret secret)) (extractToken authHeader) of
    Nothing -> throwError err401 {errBody = "Invalid or expired token"}
    Just jwt -> do
      aName <- case stringOrURIToText <$> JWT.sub (JWT.claims jwt) of
        Nothing -> throwError err401 {errBody = ""}
        Just n -> pure n
      runDbSession
        (\pool -> use pool (profileSession aName))
        ( \case
            Nothing -> throwError err401 {errBody = BL8.pack "Profile not found"}
            Just p -> pure p
        )
        Nothing

extractToken :: Text -> Text
extractToken header =
  case splitOn " " (strip header) of
    ["Bearer", t] -> t
    [t] -> t
    _ -> header

server :: ServerT AppApi App
server = (register :<|> login :<|> profile) :<|> serveDirectoryFileServer "/home/ivand/src/idimitrov.dev/_site"

mkApp :: Env -> IO Application
mkApp env = do
  pure $
    cors
      (const $ corsPolicy)
      apiApp
  where
    apiApp = serve api (hoistServer api (runApp env) server)
    cfg = envConfig env
    corsPolicy =
      case cfgEnvironment cfg of
        Development ->
          Just
            simpleCorsResourcePolicy
              { corsRequestHeaders = ["Content-Type", "Authorization"],
                corsMethods = ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
                corsOrigins = Nothing
              }
        Production -> Just simpleCorsResourcePolicy

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
