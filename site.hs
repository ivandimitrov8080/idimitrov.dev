--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}

import Data.List (nub)
import Hakyll
import Skylighting (Style, monochrome, styleToCss, zenburn)
import Skylighting.Styles (kate, monochrome, pygments, zenburn)
import System.FilePath (splitDirectories, (</>))
import System.IO.Temp (withSystemTempDirectory)
import System.Process (callProcess)
import Text.Pandoc (Block (CodeBlock), Pandoc, WriterOptions (writerHighlightStyle))
import Text.Pandoc.Walk (walk)

--------------------------------------------------------------------------------
-- Hakyll config
--------------------------------------------------------------------------------
myConfig :: Configuration
myConfig =
  defaultConfiguration
    { ignoreFile = ignoreFile'
    }
  where
    ignoreFile' p = ignoreFile defaultConfiguration p || (any (`elem` splitDirectories p) ["elm-stuff", "servant"])

--------------------------------------------------------------------------------
-- Hakyll config
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Render options
--------------------------------------------------------------------------------

codeStyle :: Style
codeStyle = zenburn

addNumberLines :: Pandoc -> Pandoc
addNumberLines = walk go
  where
    go (CodeBlock (ident, classes, attrs) code) =
      CodeBlock (ident, nub ("numberLines" : classes), attrs) code
    go x = x

myWriterOptions :: WriterOptions
myWriterOptions = defaultHakyllWriterOptions {writerHighlightStyle = Just codeStyle}

--------------------------------------------------------------------------------
-- Render options
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Site config
--------------------------------------------------------------------------------
main :: IO ()
main = hakyllWith myConfig $ do
  match "images/*" $ do
    route idRoute
    compile copyFileCompiler

  match "css/*" $ do
    route idRoute
    compile compressCssCompiler

  create ["css/syntax.css"] $ do
    route idRoute
    compile $ makeItem (styleToCss codeStyle)

  match (fromList ["about.rst", "contact.markdown"]) $ do
    route $ setExtension "html"
    compile $
      pandocCompiler
        >>= loadAndApplyTemplate "templates/default.html" defaultContext
        >>= relativizeUrls

  match "posts/**.md" $ do
    route $ setExtension "html"
    compile $
      pandocCompilerWithTransform defaultHakyllReaderOptions myWriterOptions addNumberLines
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
  elmDeps <- makePatternDependency ("src/**.elm" .||. "elm.json")

  rulesExtraDependencies [elmDeps] $ do
    match "src/Main.elm" $ do
      route $ constRoute "js/app.js"
      compile $ elmMakeCompiler ["--optimize"]

  serverDeps <- makePatternDependency "server/**.hs"

  rulesExtraDependencies [serverDeps] $ do
    match "server/Main.hs" $ do
      compile $ haskellCompiler []

  match "room.html" $ do
    route idRoute
    compile $ do
      getResourceBody
        >>= loadAndApplyTemplate "templates/default.html" defaultContext
        >>= relativizeUrls

  match (fromList ["manifest.json", "favicon.ico"]) $ do
    route idRoute
    compile $ copyFileCompiler

  match "static/**" $ do
    route idRoute
    compile $ copyFileCompiler

--------------------------------------------------------------------------------
-- Site config
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Context
--------------------------------------------------------------------------------
postCtx :: Context String
postCtx =
  dateField "date" "%B %e, %Y"
    <> defaultContext

--------------------------------------------------------------------------------
-- Context
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Compilers
--------------------------------------------------------------------------------
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

haskellCompiler :: [String] -> Compiler (Item String)
haskellCompiler extraGhcFlags = do
  entry <- getResourceFilePath
  unsafeCompiler $ do
    let out = take (length entry - 3) entry
    callProcess "ghc" $
      [entry, "-iserver", "-o", out] ++ extraGhcFlags
  makeItem ""

--------------------------------------------------------------------------------
-- Compilers
--------------------------------------------------------------------------------
