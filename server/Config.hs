{-# LANGUAGE OverloadedStrings #-}

module Config
  ( Config (..),
    readConfig,
    defaultPort,
    defaultPoolSize,
  )
where

import Data.Maybe (fromMaybe)
import Data.Text (Text, pack)
import System.Environment (getEnv, lookupEnv)

-- | Configuration for the application
-- Add more fields here for extensibility (e.g., DB name, user, etc.)
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

-- | Reads configuration from environment variables with sensible defaults.
readConfig :: IO Config
readConfig = do
  host <- pack <$> getEnv "PGHOST"
  mPoolSz <- lookupEnv "PGPOOLSIZE"
  let poolSz = maybe defaultPoolSize read mPoolSz
  pure Config {cfgPgHost = host, cfgPgPoolSize = poolSz, cfgPort = defaultPort}
