{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableInstances #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

module Main (IO, Main.main) where

import Data.Maybe (mapMaybe)
import Data.Proxy (Proxy (..))
import Data.Text (Text, pack, split, unpack)
import Data.Text qualified as T
import Data.Text.IO qualified as TIO
import Servant.API (Header, (:>))
import Servant.Auth (Auth, JWT)
import Servant.Elm
  ( DefineElm (DefineElm),
    ElmOptions (urlPrefix),
    UrlPrefix (Static),
    defElmImports,
    defElmOptions,
    defaultTypeAlterations,
    elmAlterations,
    generateElmModuleWith,
  )
import Servant.Elm qualified as Elm
import Servant.Elm.Internal.Foreign (LangElm)
import Servant.Foreign (Foreign, GenerateList, HasForeign (..), HasForeignType)
import Server
import Text.RawString.QQ (r)

generatedModulePath :: FilePath
generatedModulePath = "src/Generated/Api"

instance
  (HasForeign LangElm ftype api, HasForeignType LangElm ftype Text, HasForeignType LangElm ftype (Maybe Text)) =>
  HasForeign LangElm ftype (Auth auths val :> api)
  where
  type Foreign ftype (Auth auths val :> api) = Foreign ftype (Header "Authorization" Text :> api)
  foreignFor lang ftype Proxy req =
    foreignFor lang ftype (Proxy :: Proxy (Header "Authorization" Text :> api)) req

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

port storeToken : String -> Cmd msg


port clearToken : () -> Cmd msg


port onTokenLoaded : (Maybe String -> msg) -> Sub msg

bearerToken : Maybe String -> Maybe String
bearerToken token =
    Maybe.map (\t -> "Bearer " ++ t) token


storeLoginToken : LoginResponse -> Cmd msg
storeLoginToken response =
    storeToken response.token
    |]

postProcessModule :: IO ()
postProcessModule = do
  let mpath = generatedModulePath ++ ".elm"
  content <- TIO.readFile mpath
  let withPorts =
        T.replace "module Generated.Api" "port module Generated.Api" $
          T.replace "Maybe.map (Http.header \"Authorization\") header_Authorization" "Maybe.map (Http.header \"Authorization\") (bearerToken header_Authorization)" content
  TIO.writeFile mpath withPorts

main :: IO ()
main = generateElm

generateElm :: IO ()
generateElm = do
  let p = unpack <$> (split (== '/') $ pack generatedModulePath)
  case p of
    out : parts -> do
      generateElmModuleWith
        ( defElmOptions
            { urlPrefix = Static "http://localhost:1337"
            }
        )
        parts
        elmImportsWithPosix
        out
        [ DefineElm (Proxy :: Proxy Account),
          DefineElm (Proxy :: Proxy Profile),
          DefineElm (Proxy :: Proxy LoginResponse)
        ]
        (Proxy :: Proxy (Api '[JWT]))
      postProcessModule
