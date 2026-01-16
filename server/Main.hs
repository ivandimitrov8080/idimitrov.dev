{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeOperators #-}

module Main (IO, main) where

import Api
import Control.Monad.IO.Class (liftIO)
import Control.Monad.Reader (ReaderT, ask, runReaderT)
import Data.Functor.Contravariant
import Data.Int
import Data.Text (Text, pack)
import Data.Vector (Vector)
import Data.Vector qualified as V
import Hasql.Connection qualified as Connection
import Hasql.Connection.Setting qualified as ConnectionSetting
import Hasql.Connection.Setting.Connection qualified as ConnectionSettingConnection
import Hasql.Decoders qualified as Decoders
import Hasql.Encoders qualified as Encoders
import Hasql.Pool (Pool, UsageError, acquire, use)
import Hasql.Pool.Config qualified as PoolConfig
import Hasql.Session (Session)
import Hasql.Session qualified as Session
import Hasql.Statement (Statement (..))
import Hasql.TH qualified as TH
import Network.Wai
import Network.Wai.Handler.Warp
import Network.Wai.Middleware.Cors (cors, simpleCorsResourcePolicy)
import Servant
import System.Environment (getEnv, lookupEnv)
import System.IO
import Prelude

--------------------------------------------------------------------------------
-- Serve
--------------------------------------------------------------------------------
type AppM = ReaderT Pool Handler

runAppM :: Pool -> AppM a -> Handler a
runAppM pool app = runReaderT app pool

main :: IO ()
main = do
  serveCommand
  -- Hasql.Pool.release could be called here, but since Warp blocks and the pool is garbage collected at process exit, this is optional. For robust server/worker deployment, use bracket pattern to manage pool lifetime.
  pure ()

serveCommand :: IO ()
serveCommand = do
  hostStr <- getEnv "PGHOST"
  let port = 8080
      settings =
        setPort port $
          setBeforeMainLoop (hPutStrLn stderr ("listening on port " ++ show port)) $
            defaultSettings
      host = pack hostStr
      pstr :: Text
      pstr = "host=" <> host <> " dbname=postgres user=postgres port=5432"
  -- Pool size from env or default
  poolSize <- fmap (maybe 10 read) (lookupEnv "PGPOOLSIZE")

  let poolConfig =
        PoolConfig.settings
          [ PoolConfig.size poolSize,
            PoolConfig.staticConnectionSettings (connectionSettings pstr)
          ]
  pool <- acquire poolConfig
  runSettings settings =<< mkApp pool
  where
    connectionSettings pstr = [ConnectionSetting.connection $ ConnectionSettingConnection.string pstr]

mkApp :: Pool -> IO Application
mkApp pool = do
  let apiApp = serve itemApi (hoistServer itemApi (runAppM pool) server)
  pure $ cors (const $ Just simpleCorsResourcePolicy) apiApp

server :: ServerT ItemApi AppM
server =
  getItems
    :<|> getItemById

getItems :: AppM [Item]
getItems = do
  pool <- ask
  result <- liftIO $ use pool selectItemsSession
  case result of
    Left err -> do
      liftIO $ hPutStrLn stderr ("DB UsageError: " ++ show err)
      throwError err500
    Right tuples -> pure $ map (\(i, t, n) -> Item (fromIntegral i) (t) (n)) (V.toList tuples) -- convert Vector to list and then to Item

selectItemsSession :: Session (Vector (Int64, Text, Text))
selectItemsSession =
  Session.statement () selectItemsStatement

selectItemsStatement :: Statement () (Vector (Int64, Text, Text))
selectItemsStatement =
  [TH.vectorStatement|
    SELECT id :: int8, text :: text, name :: text
    FROM item
  |]

selectItemStatement :: Statement Int64 (Int64, Text, Text)
selectItemStatement =
  [TH.singletonStatement|
    SELECT id :: int8, text :: text, name :: text
    FROM item WHERE id = $1 :: int8
  |]

selectItemSession :: Int64 -> Session (Int64, Text, Text)
selectItemSession id =
  Session.statement (id) selectItemStatement

getItemById :: Int64 -> AppM Item
getItemById id = do
  pool <- ask
  result <- liftIO $ use pool $ selectItemSession id
  case result of
    Left err -> do
      liftIO $ hPutStrLn stderr ("DB UsageError: " ++ show err)
      throwError err500
    Right tuple -> pure $ let (i, t, n) = tuple in Item (fromIntegral i) t n

--------------------------------------------------------------------------------
-- Serve
--------------------------------------------------------------------------------
