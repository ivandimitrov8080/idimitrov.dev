{-# LANGUAGE OverloadedStrings #-}

module Handlers
  ( server,
    AppM (..),
    runAppM,
  )
where

import Api
import Control.Monad.IO.Class (liftIO)
import Control.Monad.Reader (ReaderT, ask, runReaderT)
import DB
import Data.Int (Int64)
import Data.Text (Text)
import Data.Vector qualified as V
import Hasql.Pool (Pool, UsageError)
import Servant (Handler, ServerT, err500, throwError, (:<|>) (..))
import System.IO (hPutStrLn, stderr)

-- Helpers extracted by refactor for reusability (see below)

-- AppM is now the reader over Pool for Handler
-- Move the ServerT API implementation here as well

type AppM = ReaderT Pool Handler

runAppM :: Pool -> AppM a -> Handler a
runAppM pool app = runReaderT app pool

server :: ServerT ItemApi AppM
server =
  getItems :<|> getItemById :<|> getItemByText

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
    (\pool -> runSession pool selectItemsSession)
    (\tuples -> pure $ map (\(i, t, n) -> Item (fromIntegral i) t n) (V.toList tuples))

getItemById :: Int64 -> AppM Item
getItemById itemId =
  runDbSession
    (\pool -> runSession pool (selectItemSession itemId))
    (\(i, t, n) -> pure $ Item (fromIntegral i) t n)

getItemByText :: Text -> AppM Item
getItemByText text =
  runDbSession
    (\pool -> runSession pool (selectItemTextSession text))
    (\(i, t, n) -> pure $ Item (fromIntegral i) t n)
