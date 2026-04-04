{-# LANGUAGE OverloadedStrings #-}

module Config (Config (..), Env (..), Environment (..), readConfig) where

import Data.Maybe (fromMaybe)
import Data.Text (Text, pack, strip, toLower, unpack)
import Data.Time (NominalDiffTime)
import GHC.Internal.System.Environment.Blank (getEnvDefault)
import Hasql.Pool (Pool)
import System.Environment (getEnv, lookupEnv)
import Text.Read (readMaybe)

data Env = Env
  { envConfig :: Config,
    envPool :: Pool
  }

data Environment = Development | Production
  deriving (Show, Eq)

data Config = Config
  { cfgPgHost :: Text,
    cfgPgPoolSize :: Int,
    cfgHost :: Text,
    cfgPort :: Int,
    cfgJwtSecret :: Text,
    cfgEnvironment :: Environment,
    cfgJwtExpiry :: NominalDiffTime
  }
  deriving (Show, Eq)

parseEnvironment :: Text -> Environment
parseEnvironment t =
  case env of
    "development" -> Development
    "dev" -> Development
    "production" -> Production
    "prod" -> Production
    _ -> error $ "Invalid environment: " ++ unpack env
  where
    env = toLower (strip t)

readConfig :: IO Config
readConfig = do
  host <- pack <$> getEnv "PGHOST"
  jwtSecret <- pack <$> getEnv "JWT_SECRET"
  glueHost <- pack <$> getEnvDefault "GLUE_HOST" "idimitrov.dev"
  environment <- pack <$> getEnvDefault "GLUE_ENV" "production"
  mPoolSz <- lookupEnv "PGPOOLSIZE"
  jwtExpiry <- lookupEnv "JWT_EXPIRY"
  gluePort <- lookupEnv "GLUE_PORT"
  let poolSz = maybe pz (fromMaybe pz . readMaybe) mPoolSz
      port = maybe p (fromMaybe p . readMaybe) gluePort
      expiry = maybe e (fromMaybe e . readMaybe) jwtExpiry
  pure
    Config
      { cfgPgHost = host,
        cfgPgPoolSize = poolSz,
        cfgHost = glueHost,
        cfgPort = port,
        cfgJwtSecret = jwtSecret,
        cfgJwtExpiry = expiry,
        cfgEnvironment = parseEnvironment environment
      }
  where
    p = 1337
    e = 3600
    pz = 10
