{-# LANGUAGE OverloadedStrings #-}

module App (mkApp) where

import Api
import DB (Pool)
import Handlers (AppM, runAppM, server)
import Network.Wai (Application)
import Network.Wai.Middleware.Cors (CorsResourcePolicy (corsMethods, corsRequestHeaders), cors, simpleCorsResourcePolicy)
import Servant (hoistServer, serve)

mkApp :: Pool -> IO Application
mkApp pool = do
  let apiApp = serve api (hoistServer api (runAppM pool) server)
  pure $
    cors
      ( const $
          Just
            simpleCorsResourcePolicy
              { corsRequestHeaders = ["Content-Type", "Authorization"],
                corsMethods = ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
              }
      )
      apiApp
