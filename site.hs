--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}

import Data.List (nub)
import GHC.Internal.Data.Proxy (Proxy)
import GenerateLibraryCode
import Hakyll
import Servant.Elm
  ( DefineElm (DefineElm),
    ElmOptions (urlPrefix),
    Proxy (Proxy),
    UrlPrefix (Static),
    defElmImports,
    defElmOptions,
    generateElmModuleWith,
  )
import Skylighting (Style, monochrome, styleToCss, zenburn)
import Skylighting.Styles (kate, monochrome, pygments, zenburn)
import System.Directory (createDirectoryIfMissing)
import System.FilePath (dropExtension, splitDirectories, takeDirectory, (</>))
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
    ignoreFile' p = ignoreFile defaultConfiguration p || (any (`elem` splitDirectories p) ["elm-stuff", "servant", "bin", "Generated"])

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
  match "site.hs" $ do
    compile $ haskellCompiler []

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
  js <- unsafeCompiler $
    withSystemTempDirectory "hakyll-elm" $ \dir -> do
      let out = dir </> "elm.js"
      callProcess "elm" $
        ["make", entry, "--output", out] ++ extraElmArgs
      readFile out
  makeItem js

haskellCompiler :: [String] -> Compiler (Item ())
haskellCompiler extraGhcFlags = do
  entry <- getResourceFilePath
  unsafeCompiler $ do
    let out = "bin" </> dropExtension entry
    createDirectoryIfMissing True (takeDirectory out)
    callProcess "ghc" $
      ["-outputdir", "bin", entry, "-iserver", "-o", out] ++ extraGhcFlags
  makeItem ()

--------------------------------------------------------------------------------
-- Compilers
--------------------------------------------------------------------------------
