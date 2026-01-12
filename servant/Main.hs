{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeOperators #-}

module Main where

import Data.Aeson (ToJSON)
import Data.Aeson.Types (FromJSON)
import Elm.Derive (defaultOptions, deriveBoth)
import GHC.Generics
import Network.Wai
import Network.Wai.Handler.Warp
import Network.Wai.Middleware.Cors (cors, simpleCorsResourcePolicy)
import Options.Applicative (Parser, execParser, fullDesc, hsubparser, info, metavar, progDesc, (<**>))
import Options.Applicative.Builder (command)
import Options.Applicative.Common (ParserInfo)
import Options.Applicative.Extra (helper)
import Servant
import Servant.API (Capture, Get, JSON, (:>))
import Servant.Elm
  ( DefineElm (DefineElm),
    Proxy (Proxy),
    defElmImports,
    defElmOptions,
    generateElmModuleWith,
  )
import System.IO

--------------------------------------------------------------------------------
-- Cli options
--------------------------------------------------------------------------------

data CliCommand
  = Gen
  | Serve
  deriving (Show, Eq)

data CliFlags = CliFlags
  { cliCommand :: CliCommand
  }
  deriving (Show, Eq)

commandParser :: Parser CliCommand
commandParser =
  hsubparser
    ( command
        "gen"
        (info (pure Gen) (progDesc "Generate"))
        <> command
          "serve"
          (info (pure Serve) (progDesc "Serve"))
        <> metavar "COMMAND"
    )

opts :: ParserInfo CliCommand
opts =
  info
    (commandParser <**> helper)
    ( fullDesc
        <> progDesc "CLI where first positional argument is COMMAND: gen|serve"
    )

--------------------------------------------------------------------------------
-- CLI options
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- API types
--------------------------------------------------------------------------------

data Item
  = Item
  { itemId :: Integer,
    itemText :: String
  }
  deriving (Eq, Show, Generic)

deriveBoth defaultOptions ''Item

type ItemApi =
  "item" :> Get '[JSON] [Item]
    :<|> "item" :> Capture "itemId" Integer :> Get '[JSON] Item

itemApi :: Proxy ItemApi
itemApi = Proxy

--------------------------------------------------------------------------------
-- API types
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Program
--------------------------------------------------------------------------------

main :: IO ()
main = do
  flags <- execParser opts
  case flags of
    Gen -> generateElm
    Serve -> serveCommand

--------------------------------------------------------------------------------
-- Program
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Serve
--------------------------------------------------------------------------------

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
getItems = return [exampleItem, exampleItem2]

getItemById :: Integer -> Handler Item
getItemById = \case
  0 -> return exampleItem
  _ -> throwError err404

exampleItem :: Item
exampleItem = Item 0 "example item"

exampleItem2 :: Item
exampleItem2 = Item 1 "example item 2"

--------------------------------------------------------------------------------
-- Serve
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Generate client lib
--------------------------------------------------------------------------------

generateElm :: IO ()
generateElm =
  generateElmModuleWith
    defElmOptions
    [ "Generated",
      "Api"
    ]
    defElmImports
    "src"
    [ DefineElm (Proxy :: Proxy Item)
    ]
    (Proxy :: Proxy ItemApi)

--------------------------------------------------------------------------------
-- Generate client lib
--------------------------------------------------------------------------------
