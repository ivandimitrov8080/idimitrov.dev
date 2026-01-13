{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TemplateHaskell #-}

module Api where

import Elm.Derive (defaultOptions, deriveBoth)
import GHC.Generics
import Servant
import Servant.API (Capture, Get, JSON, (:>))
import System.IO

--------------------------------------------------------------------------------
-- API types
--------------------------------------------------------------------------------

data Item
  = Item
  { itemId :: Integer,
    itemText :: String,
    itemName :: String
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
