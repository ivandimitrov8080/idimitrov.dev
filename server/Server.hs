{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE TemplateHaskell #-}

module Server (IO, main, Item, Account, Profile, Api) where

-- \| Combined server module: contains Api, DB, Handlers, Config, App wiring, and Main.
-- Each original file's content is marked with a section comment.

--------------------------------------------------------------------------------
-- SECTION: Imports
--------------------------------------------------------------------------------

import Basement.Compat.Base (Int64)
import Control.Monad.IO.Class (liftIO)
import Control.Monad.Reader (ReaderT, ask, runReaderT)
import Data.Aeson (FromJSON, ToJSON)
import Data.Int (Int64)
import Data.Maybe (fromMaybe)
import Data.Password.Argon2 (Password, PasswordHash (unPasswordHash), hashPassword, mkPassword)
import Data.Text (Text, pack)
import Data.Vector qualified as V
import Distribution.Simple.Hpc (Way (Prof))
import Elm.Derive (defaultOptions, deriveBoth)
import GHC.Generics
import Hasql.Connection.Setting qualified as ConnectionSetting
import Hasql.Connection.Setting.Connection qualified as ConnectionSettingConnection
import Hasql.Pool (Pool, UsageError, acquire, use)
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

--------------------------------------------------------------------------------
-- SECTION: Types and API (from Api.hs)
--------------------------------------------------------------------------------

data Item = Item
  { itemId :: Int64,
    itemText :: Text,
    itemName :: Text
  }
  deriving (Eq, Show, Generic)

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

-- Compile-time Elm/JSON derives (leave as hooks for later extraction)
$(deriveBoth defaultOptions ''Item)
$(deriveBoth defaultOptions ''Profile)
$(deriveBoth defaultOptions ''Account)

-- Servant API Type

type Api =
  "item" :> Get '[JSON] [Item]
    :<|> "item" :> Capture "itemId" Int64 :> Get '[JSON] Item
    :<|> "item" :> Capture "itemText" Text :> Get '[JSON] Item
    :<|> "register" :> ReqBody '[JSON] Account :> Post '[JSON] Profile
    :<|> "login" :> ReqBody '[JSON] Account :> Post '[JSON] Profile

api :: Proxy Api
api = Proxy

--------------------------------------------------------------------------------
-- SECTION: Config (from Config.hs)
--------------------------------------------------------------------------------

data Config = Config
  { cfgPgHost :: Text,
    cfgPgPoolSize :: Int,
    cfgPort :: Int
  }
  deriving (Show, Eq)

defaultPort :: Int
defaultPort = 8080

defaultPoolSize :: Int
defaultPoolSize = 10

readConfig :: IO Config
readConfig = do
  host <- pack <$> getEnv "PGHOST"
  mPoolSz <- lookupEnv "PGPOOLSIZE"
  let poolSz = maybe defaultPoolSize read mPoolSz
  pure Config {cfgPgHost = host, cfgPgPoolSize = poolSz, cfgPort = defaultPort}

--------------------------------------------------------------------------------
-- SECTION: DB (from DB.hs)
--------------------------------------------------------------------------------

withPool :: Config -> (Pool -> IO a) -> IO a
withPool cfg action = do
  let pstr = "host=" <> cfgPgHost cfg <> " dbname=postgres user=postgres port=5432"
      poolConfig =
        PoolConfig.settings
          [ PoolConfig.size (cfgPgPoolSize cfg),
            PoolConfig.staticConnectionSettings [ConnectionSetting.connection $ ConnectionSettingConnection.string pstr]
          ]
  pool <- acquire poolConfig
  action pool

selectItemsSession :: Session [Item]
selectItemsSession =
  fmap
    (\v -> map (\(i, t, n) -> Item i t n) $ V.toList v)
    (Session.statement () [TH.vectorStatement|SELECT id :: int8, text :: text, name :: text FROM item|])

selectItemSession :: Int64 -> Session Item
selectItemSession i =
  fmap
    (\(i, n, p) -> Item i n p)
    (Session.statement i [TH.singletonStatement|SELECT id :: int8, text :: text, name :: text FROM item WHERE id = $1 :: int8|])

selectItemTextSession :: Text -> Session Item
selectItemTextSession t =
  fmap
    (\(i, n, p) -> Item i n p)
    (Session.statement t [TH.singletonStatement|SELECT id :: int8, text :: text, name :: text FROM item WHERE text = $1 :: text|])

accountRegisterSession :: Account -> Session Profile
accountRegisterSession (Account _ name password _) = do
  hashed <- hashPassword $ mkPassword password
  fmap (\(name) -> Profile name) $
    Session.statement
      (name, unPasswordHash hashed)
      [TH.singletonStatement|
      INSERT INTO account (name, password)
      VALUES ($1 :: text, $2 :: text)
      RETURNING name :: text
    |]

accountLoginSession :: Account -> Session Profile
accountLoginSession (Account _ name password _) = do
  fmap (\(name) -> Profile name) $
    Session.statement
      (name)
      [TH.singletonStatement|
      SELECT name :: text
      FROM account
      WHERE name = $1 :: text
    |]

--------------------------------------------------------------------------------
-- SECTION: AppM and Handlers (from Handlers.hs)
--------------------------------------------------------------------------------

type AppM = ReaderT Pool Handler

runAppM :: Pool -> AppM a -> Handler a
runAppM pool app = runReaderT app pool

-- Helper to log DB errors
logDbError :: UsageError -> AppM ()
logDbError err = liftIO $ hPutStrLn stderr ("DB UsageError: " ++ show err)

-- Abstract runner for DB sessions
runDbSession :: (Pool -> IO (Either UsageError a)) -> (a -> AppM b) -> AppM b
runDbSession action onSuccess = do
  pool <- ask
  result <- liftIO $ action pool
  case result of
    Left err -> do
      logDbError err
      throwError err500
    Right val -> onSuccess val

getItems :: AppM [Item]
getItems =
  runDbSession
    (\pool -> use pool selectItemsSession)
    pure

getItemById :: Int64 -> AppM Item
getItemById itemId =
  runDbSession
    (\pool -> use pool (selectItemSession itemId))
    pure

getItemByText :: Text -> AppM Item
getItemByText text =
  runDbSession
    (\pool -> use pool (selectItemTextSession text))
    pure

accountRegister :: Account -> AppM Profile
accountRegister account =
  runDbSession
    (\pool -> use pool (accountRegisterSession account))
    pure

login :: Account -> AppM Profile
login account =
  runDbSession
    (\pool -> use pool (accountLoginSession account))
    pure

server :: ServerT Api AppM
server =
  getItems
    :<|> getItemById
    :<|> getItemByText
    :<|> accountRegister
    :<|> login

--------------------------------------------------------------------------------
-- SECTION: App Wiring (from App.hs)
--------------------------------------------------------------------------------

mkApp :: Pool -> IO Application
mkApp pool = do
  let apiApp = serve api (hoistServer api (runAppM pool) server)
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
-- SECTION: Main (from Main.hs)
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
    app <- mkApp pool
    runSettings settings app

--------------------------------------------------------------------------------
-- END OF FILE
--------------------------------------------------------------------------------
