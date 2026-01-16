{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE TemplateHaskell #-}

module Main (main) where

import App (mkApp)
import Config
import DB (Pool, withPool)
import Hasql.TH qualified as TH
import Network.Wai.Handler.Warp (defaultSettings, runSettings, setBeforeMainLoop, setPort)
import System.IO (hPutStrLn, stderr)

main :: IO ()
main = do
  config <- readConfig
  let port = cfgPort config
      settings =
        setPort port $
          setBeforeMainLoop (hPutStrLn stderr ("listening on port " ++ show port)) $
            defaultSettings
  withPool config $ \pool -> do
    app <- mkApp pool
    runSettings settings app
