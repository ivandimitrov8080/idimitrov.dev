{-# LANGUAGE OverloadedStrings #-}

module Handlers
  ( server,
    AppM (..),
    runAppM,
  )
where

import Api
import Api (Profile)
import Control.Monad.IO.Class (liftIO)
import Control.Monad.Reader (ReaderT, ask, runReaderT)
import Control.Monad.Trans.Resource (register)
import DB
import Data.Int (Int64)
import Data.Text (Text)
import Hasql.Pool (Pool, UsageError, use)
import Servant (Handler, ServerT, err500, throwError, (:<|>) (..))
import System.IO (hPutStrLn, stderr)

-- Helpers extracted by refactor for reusability (see below)

-- AppM is now the reader over Pool for Handler
-- Move the ServerT API implementation here as well

type AppM = ReaderT Pool Handler

runAppM :: Pool -> AppM a -> Handler a
runAppM pool app = runReaderT app pool

server :: ServerT Api AppM
server =
  getItems :<|> getItemById :<|> getItemByText :<|> accountRegister :<|> login

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
    (\items -> pure $ items)

getItemById :: Int64 -> AppM Item
getItemById itemId =
  runDbSession
    (\pool -> use pool (selectItemSession itemId))
    (\item -> pure $ item)

getItemByText :: Text -> AppM Item
getItemByText text =
  runDbSession
    (\pool -> use pool (selectItemTextSession text))
    (\item -> pure $ item)

accountRegister :: Account -> AppM Profile
accountRegister account =
  runDbSession
    (\pool -> use pool (accountRegisterSession account))
    (\acc -> pure acc)

login :: Account -> AppM Profile
login account =
  runDbSession
    (\pool -> use pool (accountLoginSession account))
    (\acc -> pure acc)
