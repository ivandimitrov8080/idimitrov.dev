{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE TemplateHaskell #-}
{-# OPTIONS_GHC -XTemplateHaskell -XQuasiQuotes #-}

module DB
  ( withPool,
    runSession,
    selectItemsSession,
    selectItemSession,
    selectItemTextSession,
    Pool,
  )
where

import Config (Config (..))
import Data.Int (Int64)
import Data.Text (Text)
import Data.Vector (Vector)
import Hasql.Connection.Setting qualified as ConnectionSetting
import Hasql.Connection.Setting.Connection qualified as ConnectionSettingConnection
import Hasql.Pool (Pool, UsageError, acquire, use)
import Hasql.Pool.Config qualified as PoolConfig
import Hasql.Session (Session)
import Hasql.Session qualified as Session
import Hasql.Statement (Statement (..))
import Hasql.TH qualified as TH

-- | Acquire pool, run action, let pool GC'd after.
withPool :: Config -> (Pool -> IO a) -> IO a
withPool cfg action = do
  let pstr = "host=" <> cfgPgHost cfg <> " dbname=postgres user=postgres port=5432"
      poolConfig =
        PoolConfig.settings
          [ PoolConfig.size (cfgPgPoolSize cfg),
            PoolConfig.staticConnectionSettings [ConnectionSetting.connection $ ConnectionSettingConnection.string pstr]
          ]
  pool <- acquire poolConfig
  action pool

runSession :: Pool -> Session a -> IO (Either UsageError a)
runSession = use

selectItemsSession :: Session (Vector (Int64, Text, Text))
selectItemsSession =
  Session.statement () selectItemsStatement

selectItemsStatement :: Statement () (Vector (Int64, Text, Text))
selectItemsStatement = [TH.vectorStatement|SELECT id :: int8, text :: text, name :: text FROM item|]

selectItemSession :: Int64 -> Session (Int64, Text, Text)
selectItemSession i =
  Session.statement i selectItemStatement

selectItemStatement :: Statement Int64 (Int64, Text, Text)
selectItemStatement = [TH.singletonStatement|SELECT id :: int8, text :: text, name :: text FROM item WHERE id = $1 :: int8|]

selectItemTextSession :: Text -> Session (Int64, Text, Text)
selectItemTextSession t =
  Session.statement t selectItemTextStatement

selectItemTextStatement :: Statement Text (Int64, Text, Text)
selectItemTextStatement = [TH.singletonStatement|SELECT id :: int8, text :: text, name :: text FROM item WHERE text = $1 :: text|]
