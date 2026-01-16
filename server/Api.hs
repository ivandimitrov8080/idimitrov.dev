{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TemplateHaskell #-}

module Api where

import Basement.Compat.Base (Int64)
import Data.Aeson (FromJSON, ToJSON)
import Data.Text (Text)
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
  { itemId :: Int64,
    itemText :: Text,
    itemName :: Text
  }
  deriving (Eq, Show, Generic)

type ItemApi =
  "item" :> Get '[JSON] [Item]
    :<|> "item" :> Capture "itemId" Int64 :> Get '[JSON] Item
    :<|> "item" :> Capture "itemText" Text :> Get '[JSON] Item

itemApi :: Proxy ItemApi
itemApi = Proxy

-- Compile-time execution instead of runtime
$(deriveBoth defaultOptions ''Item)

--------------------------------------------------------------------------------
-- API types
--------------------------------------------------------------------------------
