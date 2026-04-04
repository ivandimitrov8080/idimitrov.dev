{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}

module Main (IO, Main.main) where

import Data.Text (Text)
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
import Server
import Text.RawString.QQ (r)

elmImportsWithPosix :: Text
elmImportsWithPosix =
  defElmImports
    <> [r|
import Time exposing (Posix)
import Iso8601

jsonDecPosix : Json.Decode.Decoder Posix
jsonDecPosix =
   Iso8601.decoder

jsonEncPosix : Posix -> Value
jsonEncPosix posix =
   Iso8601.encode posix
    |]

main :: IO ()
main = generateElm

generateElm :: IO ()
generateElm =
  generateElmModuleWith
    (defElmOptions {urlPrefix = Static "http://localhost:1337"})
    [ "Generated",
      "Api"
    ]
    elmImportsWithPosix
    "src"
    [ DefineElm (Proxy :: Proxy Account),
      DefineElm (Proxy :: Proxy Profile),
      DefineElm (Proxy :: Proxy LoginResponse)
    ]
    (Proxy :: Proxy Api)
