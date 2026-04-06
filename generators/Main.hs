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
    generateElmModuleWith,
  )
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
    |]

elmPorts :: Text
elmPorts =
  [r|


-- Ports for JWT token persistence via localStorage


port storeToken : String -> Cmd msg


port clearToken : () -> Cmd msg


port onTokenLoaded : (Maybe String -> msg) -> Sub msg


-- Auth helpers


{-| Create an Authorization header value with Bearer prefix -}
bearerToken : String -> Maybe String
bearerToken token =
    Just ("Bearer " ++ token)


{-| Store a token from a LoginResponse and return the token string.
    Usage: after login/register success, call storeLoginToken to persist it.
-}
storeLoginToken : LoginResponse -> Cmd msg
storeLoginToken response =
    storeToken response.token
|]

generateAuthWrappers :: Text -> Text
generateAuthWrappers content =
  case wrappers of
    [] -> ""
    ws ->
      "\n\n-- Auto-generated Auth wrappers\n"
        <> T.concat ws
  where
    ls = T.lines content
    pairs = zip ls (drop 1 ls)
    wrappers = mapMaybe (uncurry mkWrapper) pairs

mkWrapper :: Text -> Text -> Maybe Text
mkWrapper sigLine implLine = do
  (fnName, restSig) <- parseAuthSig sigLine
  args <- parseAuthImpl fnName implLine
  let wrapperName = fnName <> "Auth"
      wrapperSig = wrapperName <> " : String -> " <> restSig
      argList = T.unwords args
      wrapperImpl =
        wrapperName
          <> " token "
          <> argList
          <> " =\n    "
          <> fnName
          <> " (bearerToken token) "
          <> argList
  pure $
    "\n\n"
      <> wrapperSig
      <> "\n"
      <> wrapperImpl
      <> "\n"

parseAuthSig :: Text -> Maybe (Text, Text)
parseAuthSig line = do
  let stripped = T.stripStart line
  (before, after) <- splitOn2 " : " stripped
  rest <- tryStripAuthParam after
  guard (not (T.null before) && not (T.null rest))
  pure (before, T.strip rest)

tryStripAuthParam :: Text -> Maybe Text
tryStripAuthParam t =
  let s = T.stripStart t
   in case T.stripPrefix "Maybe String -> " s of
        Just r -> Just r
        Nothing -> case T.stripPrefix "Maybe String ->" s of
          Just r -> Just r
          Nothing -> case T.stripPrefix "(Maybe String) -> " s of
            Just r -> Just r
            Nothing -> case T.stripPrefix "(Maybe String) ->" s of
              Just r -> Just r
              Nothing -> case T.stripPrefix "(Maybe String)" s of
                Just r -> T.stripPrefix "->" (T.stripStart r)
                Nothing -> Nothing

parseAuthImpl :: Text -> Text -> Maybe [Text]
parseAuthImpl fnName line = do
  let stripped = T.stripStart line
  rest <- T.stripPrefix (fnName <> " ") stripped
  let parts = T.words rest
  case parts of
    ("header_Authorization" : args) -> do
      -- Drop the trailing "=" from the last arg
      let cleanArgs = case reverse args of
            ("=" : as') -> reverse as'
            _ -> args
      pure cleanArgs
    _ -> Nothing

splitOn2 :: Text -> Text -> Maybe (Text, Text)
splitOn2 sep txt =
  case T.breakOn sep txt of
    (_, "") -> Nothing
    (before, after) -> Just (before, T.drop (T.length sep) after)

guard :: Bool -> Maybe ()
guard True = Just ()
guard False = Nothing

postProcessModule :: IO ()
postProcessModule = do
  let mpath = generatedModulePath ++ ".elm"
  content <- TIO.readFile mpath
  let withPorts =
        T.replace "module Generated.Api" "port module Generated.Api" content
          <> elmPorts
      authWrappers = generateAuthWrappers content
      patched = withPorts <> authWrappers
  TIO.writeFile mpath patched

main :: IO ()
main = generateElm

generateElm :: IO ()
generateElm = do
  let p = unpack <$> (split (== '/') $ pack generatedModulePath)
  case p of
    out : parts -> do
      generateElmModuleWith
        (defElmOptions {urlPrefix = Static "http://localhost:1337"})
        parts
        elmImportsWithPosix
        out
        [ DefineElm (Proxy :: Proxy Account),
          DefineElm (Proxy :: Proxy Profile),
          DefineElm (Proxy :: Proxy LoginResponse)
        ]
        (Proxy :: Proxy (Api '[JWT]))
      postProcessModule
