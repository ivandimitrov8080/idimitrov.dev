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

-- AppM is now the reader over Pool for Handler
-- Move the ServerT API implementation here as well

type AppM = ReaderT Pool Handler

runAppM :: Pool -> AppM a -> Handler a
runAppM pool app = runReaderT app pool

server :: ServerT ItemApi AppM
server =
  getItems :<|> getItemById :<|> getItemByText

getItems :: AppM [Item]
getItems = do
  pool <- ask
  result <- liftIO $ runSession pool selectItemsSession
  case result of
    Left err -> do
      liftIO $ hPutStrLn stderr ("DB UsageError: " ++ show err)
      throwError err500
    Right tuples -> pure $ map (\(i, t, n) -> Item (fromIntegral i) t n) (V.toList tuples)

getItemById :: Int64 -> AppM Item
getItemById itemId = do
  pool <- ask
  result <- liftIO $ runSession pool (selectItemSession itemId)
  case result of
    Left err -> do
      liftIO $ hPutStrLn stderr ("DB UsageError: " ++ show err)
      throwError err500
    Right (i, t, n) -> pure $ Item (fromIntegral i) t n

getItemByText :: Text -> AppM Item
getItemByText text = do
  pool <- ask
  result <- liftIO $ runSession pool (selectItemTextSession text)
  case result of
    Left err -> do
      liftIO $ hPutStrLn stderr ("DB UsageError: " ++ show err)
      throwError err500
    Right (i, t, n) -> pure $ Item (fromIntegral i) t n
