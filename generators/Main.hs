{-# LANGUAGE OverloadedStrings #-}

module Main (IO, main) where

import Api
import GHC.Internal.Data.Proxy (Proxy)
import Servant.Elm
  ( DefineElm (DefineElm),
    ElmOptions (urlPrefix),
    Proxy (Proxy),
    UrlPrefix (Static),
    defElmImports,
    defElmOptions,
    generateElmModuleWith,
  )

--------------------------------------------------------------------------------
-- Generate client lib
--------------------------------------------------------------------------------

main :: IO ()
main = generateElm

generateElm :: IO ()
generateElm =
  generateElmModuleWith
    (defElmOptions {urlPrefix = Static "http://localhost:8080"})
    [ "Generated",
      "Api"
    ]
    defElmImports
    "src"
    [ DefineElm (Proxy :: Proxy Item),
      DefineElm (Proxy :: Proxy Account),
      DefineElm (Proxy :: Proxy Profile)
    ]
    (Proxy :: Proxy Api)

--------------------------------------------------------------------------------
-- Generate client lib
--------------------------------------------------------------------------------
