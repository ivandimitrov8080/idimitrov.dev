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
import Hasql.Connection qualified as Connection
import Hasql.Connection.Setting qualified as ConnectionSetting
import Hasql.Connection.Setting.Connection qualified as ConnectionSettingConnection
import Hasql.Decoders qualified as Decoders
import Hasql.Encoders qualified as Encoders
import Hasql.Session (Session)
import Hasql.Session qualified as Session
import Hasql.Statement (Statement (..))
import Hasql.TH qualified as TH
import Network.Wai
import Network.Wai.Handler.Warp
import Network.Wai.Middleware.Cors (cors, simpleCorsResourcePolicy)
import Servant
import System.Environment (getEnv)
import System.IO
import Prelude

--------------------------------------------------------------------------------
-- Serve
--------------------------------------------------------------------------------

type AppM = ReaderT Connection.Connection Handler

runAppM :: Connection.Connection -> AppM a -> Handler a
runAppM connection app = runReaderT app connection

main :: IO ()
main = do
  serveCommand

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
  Right connection <- Connection.acquire (connectionSettings pstr)
  runSettings settings =<< mkApp connection
  where
    connectionSettings pstr = [ConnectionSetting.connection $ ConnectionSettingConnection.string pstr]

mkApp :: Connection.Connection -> IO Application
mkApp connection = do
  let apiApp = serve itemApi (hoistServer itemApi (runAppM connection) server)
  pure $ cors (const $ Just simpleCorsResourcePolicy) apiApp

server :: ServerT ItemApi AppM
server =
  getItems
    :<|> getItemById

getItems :: AppM [Item]
getItems = do
  conn <- ask
  result <- liftIO $ Session.run selectItemsSession conn
  case result of
    Left err -> do
      liftIO $ hPutStrLn stderr ("DB error: " ++ show err)
      throwError err500
    Right items -> pure items

selectItemsSession :: Session [Item]
selectItemsSession =
  Session.statement () selectItemsStatement

selectItemsStatement :: Statement () [Item]
selectItemsStatement =
  [TH.vectorStatement|
    SELECT (id :: int8, text :: text, name :: text) :: Item
    FROM item
  |]

getItemById :: Integer -> AppM Item
getItemById = \case
  0 -> pure exampleItem
  _ -> throwError err404

exampleItem :: Item
exampleItem = Item 0 "example item" "a"

exampleItem2 :: Item
exampleItem2 = Item 1 "example item 2" "b"

exampleItem3 :: Item
exampleItem3 = Item 2 "example item 3" "c"

exampleItem4 :: Item
exampleItem4 = Item 3 "example item 4" "s"

sumAndDivModSession :: Int64 -> Int64 -> Int64 -> Session (Int64, Int64)
sumAndDivModSession a b c = do
  -- Get the sum of a and b
  sumOfAAndB <- Session.statement (a, b) sumStatement
  -- Divide the sum by c and get the modulo as well
  Session.statement (sumOfAAndB, c) divModStatement

sumStatement :: Statement (Int64, Int64) Int64
sumStatement =
  [TH.singletonStatement|
    select ($1 :: int8 + $2 :: int8) :: int8
  |]

divModStatement :: Statement (Int64, Int64) (Int64, Int64)
divModStatement =
  [TH.singletonStatement|
    select
      (($1 :: int8) / ($2 :: int8)) :: int8,
      (($1 :: int8) % ($2 :: int8)) :: int8
  |]

--------------------------------------------------------------------------------
-- Serve
--------------------------------------------------------------------------------
