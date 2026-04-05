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
import Data.Text (Text)
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

-- | Orphan instance: make servant-elm treat @Auth auths val :> api@
--   as @Header "Authorization" Text :> api@ for Elm code generation.
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

-- | Static port declarations and helpers appended to every generated module
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

-- | Detect authenticated functions and generate Auth wrappers.
--
--   An authenticated function is identified by consecutive lines:
--     1. Type signature: @fnName : Maybe String -> rest@
--     2. Implementation:  @fnName header_Authorization ...@
--
--   For each match, generates:
--     @fnNameAuth : String -> rest@
--     @fnNameAuth token ... = fnName (bearerToken token) ...@
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

-- | Try to build an Auth wrapper from a type-signature line and the
--   implementation line that follows it.
mkWrapper :: Text -> Text -> Maybe Text
mkWrapper sigLine implLine = do
  -- Type signature must match: "fnName : Maybe String -> rest"
  (fnName, restSig) <- parseAuthSig sigLine
  -- Implementation must match: "fnName header_Authorization args..."
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

-- | Parse a type signature of the form @fnName : Maybe String -> rest@
--   or @fnName : (Maybe String) -> rest@.
--   Returns @Just (fnName, rest)@ on success.
parseAuthSig :: Text -> Maybe (Text, Text)
parseAuthSig line = do
  let stripped = T.stripStart line
  (before, after) <- splitOn2 " : " stripped
  rest <- tryStripAuthParam after
  guard (not (T.null before) && not (T.null rest))
  pure (before, T.strip rest)

-- | Try stripping the leading @Maybe String ->@ or @(Maybe String) ->@
--   from a type signature, accounting for varied whitespace.
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

-- | Parse an implementation line of the form @fnName header_Authorization args...@.
--   Returns @Just [arg1, arg2, ...]@ (the args after header_Authorization) on success.
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

-- | Split text on the first occurrence of a separator.
splitOn2 :: Text -> Text -> Maybe (Text, Text)
splitOn2 sep txt =
  case T.breakOn sep txt of
    (_, "") -> Nothing
    (before, after) -> Just (before, T.drop (T.length sep) after)

-- | guard for Maybe
guard :: Bool -> Maybe ()
guard True = Just ()
guard False = Nothing

-- | Path to the generated Elm module
generatedModulePath :: FilePath
generatedModulePath = "src/Generated/Api.elm"

-- | Post-process the generated Elm module:
--   1. Replace @module@ with @port module@
--   2. Append port declarations and static helpers
--   3. Auto-generate Auth wrappers for all authenticated endpoints
postProcessModule :: IO ()
postProcessModule = do
  content <- TIO.readFile generatedModulePath
  let withPorts =
        T.replace "module Generated.Api" "port module Generated.Api" content
          <> elmPorts
      authWrappers = generateAuthWrappers content
      patched = withPorts <> authWrappers
  TIO.writeFile generatedModulePath patched

main :: IO ()
main = generateElm

generateElm :: IO ()
generateElm = do
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
    (Proxy :: Proxy (Api '[JWT]))
  postProcessModule
