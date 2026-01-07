--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}

import Hakyll
import System.FilePath ((</>))
import System.IO.Temp (withSystemTempDirectory)
import System.Process (callProcess)

--------------------------------------------------------------------------------
main :: IO ()
main = hakyll $ do
  match "images/*" $ do
    route idRoute
    compile copyFileCompiler

  match "css/*" $ do
    route idRoute
    compile compressCssCompiler

  match (fromList ["about.rst", "contact.markdown"]) $ do
    route $ setExtension "html"
    compile $
      pandocCompiler
        >>= loadAndApplyTemplate "templates/default.html" defaultContext
        >>= relativizeUrls

  match "posts/*" $ do
    route $ setExtension "html"
    compile $
      pandocCompiler
        >>= loadAndApplyTemplate "templates/post.html" postCtx
        >>= loadAndApplyTemplate "templates/default.html" postCtx
        >>= relativizeUrls

  create ["archive.html"] $ do
    route idRoute
    compile $ do
      posts <- recentFirst =<< loadAll "posts/*"
      let archiveCtx =
            listField "posts" postCtx (return posts)
              <> constField "title" "Archives"
              <> defaultContext

      makeItem ""
        >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
        >>= loadAndApplyTemplate "templates/default.html" archiveCtx
        >>= relativizeUrls

  match "index.html" $ do
    route idRoute
    compile $ do
      posts <- recentFirst =<< loadAll "posts/*"
      let indexCtx =
            listField "posts" postCtx (return posts)
              <> defaultContext

      getResourceBody
        >>= applyAsTemplate indexCtx
        >>= loadAndApplyTemplate "templates/default.html" indexCtx
        >>= relativizeUrls

  match "templates/*" $ compile templateBodyCompiler

  -- Rebuild the JS if *any* Elm file changes (not just the entrypoint).
  elmDeps <- makePatternDependency "src/**/*.elm"

  rulesExtraDependencies [elmDeps] $ do
    -- Entry point: elm/src/Main.elm  ->  assets/elm/main.js
    match "src/Main.elm" $ do
      route $ constRoute "js/app.js"
      compile $ elmMakeCompiler ["--optimize"]

  match "room.html" $ do
    route idRoute
    compile $ do
      getResourceBody
        >>= loadAndApplyTemplate "templates/default.html" defaultContext
        >>= relativizeUrls

--------------------------------------------------------------------------------
postCtx :: Context String
postCtx =
  dateField "date" "%B %e, %Y"
    <> defaultContext

--------------------------------------------------------------------------------

-- | Compile an Elm entrypoint to JS using `elm make`.
--   Usage: match the entrypoint file and route it to a .js.
elmMakeCompiler :: [String] -> Compiler (Item String)
elmMakeCompiler extraElmArgs = do
  entry <- getResourceFilePath
  js <- unsafeCompiler $
    withSystemTempDirectory "hakyll-elm" $ \dir -> do
      let out = dir </> "elm.js"
      callProcess "elm" $
        ["make", entry, "--output", out] ++ extraElmArgs
      readFile out
  makeItem js

--------------------------------------------------------------------------------
