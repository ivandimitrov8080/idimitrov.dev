{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE TemplateHaskell #-}

module DB
  ( withPool,
    selectItemsSession,
    selectItemSession,
    selectItemTextSession,
    accountRegisterSession,
    accountLoginSession,
    Pool,
  )
where

import Api (Account (..), Item (..), Profile (..))
import Config (Config (..))
import Data.Int (Int64)
import Data.Password.Argon2 (Password, PasswordHash (unPasswordHash), hashPassword, mkPassword)
import Data.Text (Text)
import Data.Vector qualified as V
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

selectItemsSession :: Session [Item]
selectItemsSession =
  fmap
    (\v -> map (\(i, t, n) -> Item i t n) $ V.toList v)
    (Session.statement () [TH.vectorStatement|SELECT id :: int8, text :: text, name :: text FROM item|])

selectItemSession :: Int64 -> Session Item
selectItemSession i =
  fmap (\(i, n, p) -> Item i n p) $
    Session.statement
      i
      [TH.singletonStatement|SELECT id :: int8, text :: text, name :: text FROM item WHERE id = $1 :: int8|]

selectItemTextSession :: Text -> Session Item
selectItemTextSession t =
  fmap (\(i, n, p) -> Item i n p) $
    Session.statement
      t
      [TH.singletonStatement|SELECT id :: int8, text :: text, name :: text FROM item WHERE text = $1 :: text|]

accountRegisterSession :: Account -> Session Profile
accountRegisterSession (Account _ name password _) = do
  hashed <- hashPassword $ mkPassword password
  fmap (\(name) -> Profile name) $
    Session.statement
      (name, unPasswordHash hashed)
      [TH.singletonStatement|
        INSERT INTO account (name, password)
        VALUES ($1 :: text, $2 :: text)
        RETURNING name :: text
      |]

accountLoginSession :: Account -> Session Profile
accountLoginSession (Account _ name password _) = do
  fmap (\(name) -> Profile name) $
    Session.statement
      (name)
      [TH.singletonStatement|
        SELECT name :: text
        FROM account
        WHERE name = $1 :: text
      |]
