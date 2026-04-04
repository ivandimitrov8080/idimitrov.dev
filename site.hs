--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}

import Config (Config (cfgHost), readConfig)
import Data.List (nub)
import Data.Text qualified as T
import Debug.Trace (trace)
import GHC.Internal.Data.Proxy (Proxy)
import Hakyll
import Skylighting (Style, monochrome, styleToCss, zenburn)
import Skylighting.Styles (kate, monochrome, pygments, zenburn)
import System.Directory (createDirectoryIfMissing)
import System.FilePath (dropExtension, splitDirectories, takeDirectory, (</>))
import System.IO.Temp (withTempDirectory)
import System.Process (callProcess)
import Text.Pandoc (Block (CodeBlock), Pandoc, WriterOptions (writerHighlightStyle))
import Text.Pandoc.Definition (Inline (Link))
import Text.Pandoc.Options (Extension (Ext_link_attributes), ReaderOptions (readerExtensions), extensionsFromList)
import Text.Pandoc.Walk (walk)

cfg :: Configuration
cfg =
  defaultConfiguration
    { ignoreFile = ignoreFile'
    }
  where
    dirsToIgnore = ["elm-stuff", "servant", "bin", "Generated", "server", ".devenv", ".direnv", ".git"]
    ignoreFile' p = ignoreFile defaultConfiguration p || (any (`elem` splitDirectories p) dirsToIgnore)

codeStyle :: Style
codeStyle = zenburn

addNumberLines :: Pandoc -> Pandoc
addNumberLines = walk go
  where
    go (CodeBlock (ident, classes, attrs) code) =
      CodeBlock (ident, nub ("numberLines" : classes), attrs) code
    go x = x

addNewtabExternalLinks :: Config -> Pandoc -> Pandoc
addNewtabExternalLinks cfg = walk go
  where
    go (Link (ident, classes, kvs) label (url, title))
      | notCurrentHost url =
          Link
            ( ident,
              classes,
              addTargetAndRel kvs
            )
            label
            (url, title)
    go x = x
    addTargetAndRel kvs = kvs ++ [target, rel]
      where
        target = ("target", "_blank")
        rel = ("rel", "noopener noreferrer")
    notCurrentHost u =
      not $ ("http://" <> siteHost) `T.isPrefixOf` u || ("https://" <> siteHost) `T.isPrefixOf` u
    siteHost = cfgHost cfg

myTransformOptions :: Config -> Pandoc -> Pandoc
myTransformOptions cfg = addNumberLines . addNewtabExternalLinks cfg

myReaderOptions :: ReaderOptions
myReaderOptions =
  defaultHakyllReaderOptions
    { readerExtensions =
        readerExtensions defaultHakyllReaderOptions
          <> extensionsFromList [Ext_link_attributes]
    }

myWriterOptions :: WriterOptions
myWriterOptions = defaultHakyllWriterOptions {writerHighlightStyle = Just codeStyle}

--------------------------------------------------------------------------------
-- Render options
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Site config
--------------------------------------------------------------------------------
main :: IO ()
main = hakyllWith cfg $ do
  config <- preprocess readConfig
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
      pandocCompilerWith myReaderOptions myWriterOptions
        >>= loadAndApplyTemplate "templates/default.html" defaultContext
        >>= relativizeUrls

  match "posts/**.md" $ do
    route $ setExtension "html"
    compile $
      pandocCompilerWithTransform myReaderOptions myWriterOptions (myTransformOptions config)
        >>= loadAndApplyTemplate "templates/post.html" postCtx
        >>= loadAndApplyTemplate "templates/default.html" postCtx
        >>= relativizeUrls

  create ["archive.html"] $ do
    route idRoute
    compile $ do
      posts <- recentFirst =<< loadAll "posts/*"
      let archiveCtx =
            listField "posts" postCtx (pure posts)
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
            listField "posts" postCtx (pure posts)
              <> defaultContext

      getResourceBody
        >>= applyAsTemplate indexCtx
        >>= loadAndApplyTemplate "templates/default.html" indexCtx
        >>= relativizeUrls

  match "templates/*" $ compile templateBodyCompiler

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

  elmDeps <- makePatternDependency ("src/**.elm" .||. "elm.json")

  rulesExtraDependencies [elmDeps] $ do
    match "src/Main.elm" $ do
      route $ constRoute "js/app.js"
      compile $ elmMakeCompiler ["--optimize"]

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
  js <- unsafeCompiler $ do
    let tmp = (tmpDirectory cfg)
    createDirectoryIfMissing True tmp
    withTempDirectory tmp "hakyll-elm" $ \dir -> do
      let out = trace dir $ dir </> "elm.js"
      callProcess "elm" $
        ["make", entry, "--output", out] ++ extraElmArgs
      readFile out
  makeItem js

--------------------------------------------------------------------------------
-- Compilers
--------------------------------------------------------------------------------
