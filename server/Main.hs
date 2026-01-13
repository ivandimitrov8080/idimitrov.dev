{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeOperators #-}

module Main (Item, ItemApi, IO, main) where

import Api
import Network.Wai
import Network.Wai.Handler.Warp
import Network.Wai.Middleware.Cors (cors, simpleCorsResourcePolicy)
import Servant
import System.IO

--------------------------------------------------------------------------------
-- Serve
--------------------------------------------------------------------------------

main :: IO ()
main = do
  serveCommand

serveCommand :: IO ()
serveCommand = do
  let port = 8080
      settings =
        setPort port $
          setBeforeMainLoop (hPutStrLn stderr ("listening on port " ++ show port)) $
            defaultSettings
  runSettings settings =<< mkApp

mkApp :: IO Application
mkApp = do
  let apiApp = serve itemApi server
  pure $ cors (const $ Just simpleCorsResourcePolicy) apiApp

server :: Server ItemApi
server =
  getItems
    :<|> getItemById

getItems :: Handler [Item]
getItems = return [exampleItem, exampleItem2, exampleItem3, exampleItem4]

getItemById :: Integer -> Handler Item
getItemById = \case
  0 -> return exampleItem
  _ -> throwError err404

exampleItem :: Item
exampleItem = Item 0 "example item" "a"

exampleItem2 :: Item
exampleItem2 = Item 1 "example item 2" "b"

exampleItem3 :: Item
exampleItem3 = Item 2 "example item 3" "c"

exampleItem4 :: Item
exampleItem4 = Item 3 "example item 4" "s"

--------------------------------------------------------------------------------
-- Serve
--------------------------------------------------------------------------------
