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
import Data.Aeson (toJSON)
import Data.ByteString (ByteString)
import Data.ByteString.Lazy.Char8 qualified as BL8
import Data.Int (Int64)
import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe)
import Data.Password.Argon2 (Argon2, Password, PasswordCheck (..), PasswordHash (..), checkPassword, hashPassword, mkPassword)
import Data.Text (Text, pack, unpack)
import Data.Time.Clock (getCurrentTime)
import Data.Time.Clock.POSIX (utcTimeToPOSIXSeconds)
import Data.Vector qualified as V
import Distribution.Simple.Hpc (Way (Prof))
import Elm.Derive (defaultOptions, deriveBoth)
import GHC.Generics
import Hasql.Connection.Setting qualified as ConnectionSetting
import Hasql.Connection.Setting.Connection qualified as ConnectionSettingConnection
import Hasql.Pool (Pool, UsageError (SessionUsageError), acquire, use)
import Hasql.Pool.Config qualified as PoolConfig
import Hasql.Session (Session)
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
import Web.JWT qualified as JWT

--------------------------------------------------------------------------------
-- SECTION: Types and API
--------------------------------------------------------------------------------

data Account = Account
  { accountId :: Maybe Int64,
    accountName :: Text,
    accountPassword :: Text,
    accountProfile :: Profile
  }
  deriving (Eq, Show, Generic)

data Profile = Profile
  { profileName :: Text
  }
  deriving (Eq, Show, Generic)

data LoginResponse = LoginResponse
  { token :: Text,
    profile :: Profile
  }
  deriving (Eq, Show, Generic)

-- Compile-time Elm/JSON derives
$(deriveBoth defaultOptions ''Profile)
$(deriveBoth defaultOptions ''Account)
$(deriveBoth defaultOptions ''LoginResponse)

type Api =
  "register" :> ReqBody '[JSON] Account :> Post '[JSON] LoginResponse
    :<|> "login" :> ReqBody '[JSON] Account :> Post '[JSON] LoginResponse

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

accountRegisterSession :: Account -> Session Profile
accountRegisterSession (Account _ name password _) = do
  hashed <- hashPassword $ mkPassword password
  fmap (\name' -> Profile name') $
    Session.statement
      (name, unPasswordHash hashed)
      [TH.singletonStatement|
      INSERT INTO account (name, password)
      VALUES ($1 :: text, $2 :: text)
      RETURNING name :: text
    |]

accountLoginSession :: Account -> Session (Maybe Account)
accountLoginSession acc =
  Session.statement
    (accountName acc)
    [TH.maybeStatement|
      SELECT id :: int8, name :: text, password :: text FROM account WHERE name = $1 :: text
    |]
    >>= \case
      Nothing -> pure Nothing
      Just (aid, name', dbHash) ->
        pure $
          Just $
            Account
              { accountId = Just aid,
                accountName = name',
                accountPassword = dbHash,
                accountProfile = accountProfile acc
              }

logDbError :: UsageError -> AppM ()
logDbError err = liftIO $ hPutStrLn stderr ("DB UsageError: " ++ show err)

-- | Optionally handle UsageError specially, e.g. for unique constraint
runDbSession :: (Pool -> IO (Either UsageError a)) -> (a -> AppM b) -> Maybe (UsageError -> AppM b) -> AppM b
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

type AppM = ReaderT Env Handler

runAppM :: Env -> AppM a -> Handler a
runAppM env app = runReaderT app env

mkProfile :: Text -> Profile
mkProfile name = Profile name

validatePassword :: Text -> Text -> Bool
validatePassword input dbHash =
  case checkPassword (mkPassword input) (PasswordHash dbHash) of
    PasswordCheckSuccess -> True
    _ -> False

-- Build JWT claims for a user (pure)
mkJWTClaims :: Text -> Profile -> JWT.NumericDate -> JWT.JWTClaimsSet
mkJWTClaims accountName profile iatVal =
  JWT.JWTClaimsSet
    { JWT.sub = JWT.stringOrURI accountName,
      JWT.iat = Just iatVal,
      JWT.exp = Nothing,
      JWT.nbf = Nothing,
      JWT.iss = Nothing,
      JWT.aud = Nothing,
      JWT.jti = Nothing,
      JWT.unregisteredClaims = JWT.ClaimsMap $ Map.fromList [("profile", toJSON profile)]
    }

mkLoginResponse :: Text -> Profile -> LoginResponse
mkLoginResponse token profile = LoginResponse {token = token, profile = profile}

pureJWTToken :: Text -> JWT.JWTClaimsSet -> Text
pureJWTToken secret claims = JWT.encodeSigned (JWT.hmacSecret secret) mempty claims

pureLoginResponse :: Text -> Profile -> LoginResponse
pureLoginResponse token profile = LoginResponse {token = token, profile = profile}

mkAuthToken :: Text -> Text -> Profile -> JWT.NumericDate -> Text
mkAuthToken secret accountName profile iatVal =
  pureJWTToken secret (mkJWTClaims accountName profile iatVal)

mkAuthResponse :: Text -> Text -> Profile -> JWT.NumericDate -> LoginResponse
mkAuthResponse secret accountName profile iatVal =
  pureLoginResponse (mkAuthToken secret accountName profile iatVal) profile

register :: Account -> AppM LoginResponse
register account =
  runDbSession
    (\pool -> use pool (accountRegisterSession account))
    ( \profile -> do
        env <- ask
        let secret = cfgJwtSecret (envConfig env)
        now <- liftIO getCurrentTime
        case JWT.numericDate (utcTimeToPOSIXSeconds now) of
          Just iatVal -> pure $ mkAuthResponse secret (accountName account) profile iatVal
          Nothing -> throwError err500 {Servant.errBody = BL8.pack "Failed to generate JWT iat"}
    )
    (Just handleRegisterDbError)

-- | Custom handler for register DB errors
handleRegisterDbError :: UsageError -> AppM LoginResponse
handleRegisterDbError err =
  case err of
    SessionUsageError sessionErr ->
      case sessionErr of
        _ ->
          if "23505" `elem` words (show err)
            then throwError err409 {Servant.errBody = BL8.pack "Username already exists."}
            else throwError err500
    _ -> throwError err500

-- | Dedicated session for login
login :: Account -> AppM LoginResponse
login account =
  runDbSession
    (\pool -> use pool (accountLoginSession account))
    ( \res -> case res of
        Nothing -> throwError err401 {Servant.errBody = BL8.pack "Invalid login or password"}
        Just dbAccount ->
          if validatePassword (accountPassword account) (accountPassword dbAccount)
            then do
              env <- ask
              let secret = cfgJwtSecret (envConfig env)
                  profile = accountProfile dbAccount
              now <- liftIO getCurrentTime
              case JWT.numericDate (utcTimeToPOSIXSeconds now) of
                Just iatVal -> pure $ mkAuthResponse secret (accountName account) profile iatVal
                Nothing -> throwError err500 {Servant.errBody = BL8.pack "Failed to generate JWT iat"}
            else throwError err401 {Servant.errBody = BL8.pack "Invalid login or password"}
    )
    Nothing

server :: ServerT Api AppM
server = register :<|> login

mkApp :: Env -> IO Application
mkApp env = do
  let apiApp = serve api (hoistServer api (runAppM env) server)
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
