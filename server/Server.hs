{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

module Server (main, Account, Profile, LoginResponse, AuthUser, Protected, Unprotected, Api) where

import Config
import Control.Monad.IO.Class (liftIO)
import Control.Monad.Reader (ReaderT, ask, runReaderT)
import Crypto.JOSE.JWK (JWK)
import Data.Aeson (FromJSON, ToJSON)
import Data.ByteString.Lazy qualified as BL
import Data.ByteString.Lazy.Char8 qualified as BL8
import Data.Int (Int64)
import Data.Password.Argon2 (PasswordCheck (..), PasswordHash (..), checkPassword, hashPassword, mkPassword)
import Data.Text (Text, length, null, pack, unpack)
import Data.Text.Encoding (decodeUtf8)
import Data.Time.Clock (UTCTime, addUTCTime, getCurrentTime)
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
import Servant (Context (..), Handler, Proxy (..), Raw, ServerT, err400, err401, err409, err500, errBody, hoistServerWithContext, serveDirectoryFileServer, serveWithContext, throwError, (:<|>) (..))
import Servant.API (Get, JSON, Post, ReqBody, (:>))
import Servant.Auth (Auth, JWT)
import Servant.Auth.Server (AuthResult (..), CookieSettings (..), FromJWT, IsSecure (..), JWTSettings, ToJWT, defaultCookieSettings, defaultJWTSettings, makeJWT, readKey, throwAll, writeKey)
import Servant.Auth.Server qualified as SAS
import System.Directory (doesFileExist)
import System.IO (hPutStrLn, stderr)

-- | Authenticated user payload embedded in JWT claims
data AuthUser = AuthUser
  { authUserName :: Text
  }
  deriving (Eq, Show, Generic)

instance FromJSON AuthUser

instance ToJSON AuthUser

instance FromJWT AuthUser

instance ToJWT AuthUser

data Env = Env
  { envConfig :: Config,
    envPool :: Pool,
    envJwtSettings :: JWTSettings,
    envCookieSettings :: CookieSettings
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

-- | Routes that require JWT authentication
type Protected =
  "profile" :> Get '[JSON] Profile

-- | Routes that do not require authentication
type Unprotected =
  "register" :> ReqBody '[JSON] Account :> Post '[JSON] LoginResponse
    :<|> "login" :> ReqBody '[JSON] Account :> Post '[JSON] LoginResponse

-- | Full API parameterised over authentication methods
type Api auths = (Auth auths AuthUser :> Protected) :<|> Unprotected

type AppApi = Api '[JWT] :<|> Raw

api :: Proxy AppApi
api = Proxy

type CtxTypes = '[CookieSettings, JWTSettings]

ctxProxy :: Proxy CtxTypes
ctxProxy = Proxy

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
profileSession aName = do
  Session.statement
    aName
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

-- | Create a JWT token for the given user
createToken :: JWTSettings -> AuthUser -> Maybe UTCTime -> App Text
createToken jwtCfg user mExpiry = do
  eToken <- liftIO $ makeJWT user jwtCfg mExpiry
  case eToken of
    Left _err -> throwError err500 {errBody = "Failed to create JWT"}
    Right tokenBS -> pure $ decodeUtf8 (BL.toStrict tokenBS)

-- | Build a LoginResponse by minting a JWT for the given account name
issueLoginResponse :: Text -> Maybe Profile -> App LoginResponse
issueLoginResponse name mProfile = do
  env <- ask
  now <- liftIO getCurrentTime
  let jwtCfg = envJwtSettings env
      expiry = cfgJwtExpiry (envConfig env)
      expiryTime = Just $ addUTCTime expiry now
      authUser = AuthUser name
  t <- createToken jwtCfg authUser expiryTime
  pure $ LoginResponse {token = t, responseProfile = mProfile}

-- | Validate that account name and password are non-empty
validateAccountInput :: Account -> Either Text Account
validateAccountInput acc
  | Data.Text.null (accountName acc) = Left "Missing or empty accountName"
  | Data.Text.null (accountPassword acc) = Left "Missing or empty accountPassword"
  | otherwise = Right acc

register :: Account -> App LoginResponse
register account =
  case validateAccountInput account of
    Left errMsg -> throwError err400 {errBody = BL8.pack (unpack errMsg)}
    Right validAcc ->
      runDbSession
        (\pool -> use pool (accountRegisterSession validAcc))
        (\_ -> issueLoginResponse (accountName validAcc) Nothing)
        (Just handleRegisterDbError)

handleRegisterDbError :: UsageError -> App LoginResponse
handleRegisterDbError (SessionUsageError (QueryError _ _ (ResultError (Session.ServerError "23505" _ _ _ _)))) =
  throwError err409 {errBody = BL8.pack "Username already exists"}
handleRegisterDbError _ = throwError err500

login :: Account -> App LoginResponse
login account = do
  case validateAccountInput account of
    Left errMsg -> throwError err400 {errBody = BL8.pack (unpack errMsg)}
    Right validAcc ->
      runDbSession
        (\pool -> use pool (accountLoginSession validAcc))
        ( \case
            Nothing -> throwError err401 {errBody = BL8.pack "Invalid login or password"}
            Just dbAccount
              | validatePassword (accountPassword validAcc) (accountPassword dbAccount) ->
                  issueLoginResponse (accountName validAcc) (accountProfile dbAccount)
              | otherwise -> throwError err401 {errBody = BL8.pack "Invalid login or password"}
        )
        Nothing

-- | Retrieve the profile of the currently authenticated user via JWT
profile :: AuthUser -> App Profile
profile user =
  runDbSession
    (\pool -> use pool (profileSession (authUserName user)))
    ( \case
        Nothing -> throwError err401 {errBody = BL8.pack "Profile not found"}
        Just p -> pure p
    )
    Nothing

-- | Handler for protected routes; rejects unauthenticated requests
protected :: AuthResult AuthUser -> ServerT Protected App
protected (Authenticated user) = profile user
protected _ = throwAll err401 {errBody = "Invalid or expired token"}

-- | Handler for unprotected (public) routes
unprotected :: ServerT Unprotected App
unprotected = register :<|> login

server :: Config -> ServerT AppApi App
server cfg = (protected :<|> unprotected) :<|> serveDirectoryFileServer (cfgStaticFiles cfg)

-- | Load a JWK from file, or generate and persist a new one
loadOrCreateKey :: FilePath -> IO JWK
loadOrCreateKey keyFile = do
  exists <- doesFileExist keyFile
  if exists
    then readKey keyFile
    else do
      hPutStrLn stderr $ "No JWT key found at " ++ keyFile ++ ", generating new key..."
      writeKey keyFile
      readKey keyFile

mkApp :: Env -> IO Application
mkApp env = do
  pure $
    cors
      (const corsPolicy)
      apiApp
  where
    cfg = envConfig env
    jwtCfg = envJwtSettings env
    cookieCfg = envCookieSettings env
    ctx = cookieCfg :. jwtCfg :. EmptyContext
    apiApp = serveWithContext api ctx (hoistServerWithContext api ctxProxy (runApp env) $ server cfg)
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
  jwk <- loadOrCreateKey (cfgJwtKeyFile config)
  let jwtCfg = defaultJWTSettings jwk
      cookieCfg =
        case cfgEnvironment config of
          Development -> defaultCookieSettings {SAS.cookieIsSecure = SAS.NotSecure}
          Production -> defaultCookieSettings
  withPool config $ \pool -> do
    let env =
          Env
            { envConfig = config,
              envPool = pool,
              envJwtSettings = jwtCfg,
              envCookieSettings = cookieCfg
            }
    app <- mkApp env
    runSettings settings app
