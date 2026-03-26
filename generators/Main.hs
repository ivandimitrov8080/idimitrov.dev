{-# LANGUAGE OverloadedStrings #-}

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

--------------------------------------------------------------------------------
-- Generate client lib
--------------------------------------------------------------------------------

-- | Extra Elm imports and helpers for UTCTime <-> Posix mapping
elmImportsWithPosix :: Text
elmImportsWithPosix =
  defElmImports
    <> "\nimport Time exposing (Posix)\n\
       \\n\
       \jsonDecPosix : Json.Decode.Decoder Posix\n\
       \jsonDecPosix =\n\
       \    Json.Decode.int |> Json.Decode.map Time.millisToPosix\n\
       \\n\
       \jsonEncPosix : Posix -> Value\n\
       \jsonEncPosix posix =\n\
       \    Json.Encode.int (Time.posixToMillis posix)\n"

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
