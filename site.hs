--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}

import Config (Config (cfgDefaultDescription, cfgHost), readConfig)
import Data.Char (toUpper)
import Data.List (intercalate, nub, sortOn)
import Data.Ord (Down (..))
import Data.Text qualified as T
import Data.Time.Calendar (addGregorianYearsClip, toGregorian)
import Data.Time.Clock (getCurrentTime, utctDay)
import Data.Time.Format (defaultTimeLocale, formatTime)
import Debug.Trace (trace)
import GHC.Internal.Data.Proxy (Proxy)
import Hakyll
import Hakyll.Core.Dependencies (DependencyKind (KindContent))
import Skylighting (Style, monochrome, styleToCss, zenburn)
import Skylighting.Styles (kate, monochrome, pygments, zenburn)
import System.Directory (createDirectoryIfMissing)
import System.FilePath (dropExtension, splitDirectories, takeDirectory, (</>))
import System.IO.Temp (withTempDirectory)
import System.Process (callProcess)
import Text.Blaze.Html (toHtml, toValue, (!))
import Text.Blaze.Html.Renderer.String (renderHtml)
import Text.Blaze.Html5 qualified as H
import Text.Blaze.Html5.Attributes qualified as A
import Text.Pandoc (Block (CodeBlock), Pandoc, WriterOptions (writerHighlightStyle))
import Text.Pandoc.Definition (Inline (Link))
import Text.Pandoc.Options (Extension (Ext_link_attributes), ReaderOptions (readerExtensions), extensionsFromList)
import Text.Pandoc.Walk (walk)
import Unicode.Char (toLower)

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

humanizeSlug :: String -> String
humanizeSlug = unwords . map cap . words . map (\c -> if c == '-' then ' ' else c)
  where
    cap "" = ""
    cap (c : cs) = toUpper c : map toLower cs

postCtx :: Context String
postCtx =
  dateField "date" "%B %e, %Y"
    <> defaultContext

categoryCtx :: Tags -> Context String
categoryCtx categories =
  field "title" (\i -> pure $ humanizeSlug (itemBody i))
    <> field "slug" (\i -> pure $ itemBody i)
    <> field "url" (\i -> pure . toUrl . toFilePath $ tagsMakeId categories (itemBody i))
    <> field "count" (\i -> pure (show $ maybe 0 length (lookup (itemBody i) (tagsMap categories))))
    <> defaultContext

makeCategories :: Tags -> [String]
makeCategories categories = (map fst (pinnedPart ++ restSorted))
  where
    pinned :: [String]
    pinned = ["my-work"]

    categoriesWithCounts :: [(String, Int)]
    categoriesWithCounts = [(slug, length ids) | (slug, ids) <- tagsMap categories]

    pinnedPart :: [(String, Int)]
    pinnedPart = [(slug, n) | slug <- pinned, Just n <- [lookup slug categoriesWithCounts]]

    restPart :: [(String, Int)]
    restPart = [(slug, n) | (slug, n) <- categoriesWithCounts, slug `notElem` pinned]

    restSorted :: [(String, Int)]
    restSorted = sortOn (\(slug, n) -> (Down n, humanizeSlug slug)) restPart

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

-- | Generate sitemap XML for all pages
sitemapContext :: Config -> Context String
sitemapContext cfg =
  field "siteRoot" (\_ -> pure $ "https://" <> T.unpack (cfgHost cfg))
    <> defaultContext

-- | Get current ISO 8601 date
currentDate :: IO String
currentDate = formatTime defaultTimeLocale "%Y-%m-%d" <$> getCurrentTime

-- | Get expiry date (1 year from now) in ISO 8601 format
expiryDate :: IO String
expiryDate = do
  now <- getCurrentTime
  let day = utctDay now
      (y, m, d) = toGregorian day
      expiry = addGregorianYearsClip 1 day
  pure $ formatTime defaultTimeLocale "%Y-%m-%dT%H:%M:%S%z" (now {utctDay = expiry})

main :: IO ()
main = hakyllWith cfg $ do
  cfg <- preprocess readConfig
  categories <- buildCategories "posts/**" (fromCapture "category/*.html")

  -- Robots.txt with dynamic host
  create ["robots.txt"] $ do
    route idRoute
    compile $ do
      let host = T.unpack (cfgHost cfg)
          robotsContent =
            "User-agent: *\n\
            \Allow: /\n\
            \\n\
            \Sitemap: https://"
              <> host
              <> "/sitemap.xml\n"
      makeItem robotsContent

  -- Humans.txt with current date
  create ["humans.txt"] $ do
    route idRoute
    compile $ do
      date <- unsafeCompiler currentDate
      let humansContent =
            "/* TEAM */\n\
            \Developer: Ivan Dimitrov\n\
            \Site: https://idimitrov.dev\n\
            \Location: Bulgaria\n\
            \\n\
            \/* THANKS */\n\
            \Hakyll: Static site generation\n\
            \Elm: Frontend architecture\n\
            \Nix: Reproducible builds\n\
            \\n\
            \/* SITE */\n\
            \Last update: "
              <> date
              <> "\n\
                 \Standards: HTML5, CSS3\n\
                 \Components: Hakyll, Elm, Servant, PostgreSQL\n\
                 \Software: Haskell, Elm, Nix\n"
      makeItem humansContent

  -- Security.txt with expiry date
  create [".well-known/security.txt"] $ do
    route idRoute
    compile $ do
      expires <- unsafeCompiler expiryDate
      let securityContent =
            "Contact: mailto:ivan@idimitrov.dev\n\
            \Expires: "
              <> expires
              <> "\n\
                 \Preferred-Languages: en, bg\n\
                 \Canonical: https://idimitrov.dev/.well-known/security.txt\n"
      makeItem securityContent

  -- Sitemap.xml
  create ["sitemap.xml"] $ do
    route idRoute
    compile $ do
      posts <- recentFirst =<< loadAll ("posts/**" .&&. hasNoVersion)
      pages <- loadAll (fromList ["about.rst", "contact.markdown", "room.md"] .&&. hasNoVersion)
      let siteCtx = sitemapContext cfg
          allPages = posts <> pages
          sitemapCtx =
            listField "pages" (siteCtx <> postCtx) (pure allPages)
              <> siteCtx
      makeItem ""
        >>= loadAndApplyTemplate "templates/sitemap.xml" sitemapCtx

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
      pandocCompilerWithTransform myReaderOptions myWriterOptions (myTransformOptions cfg)
        >>= loadAndApplyTemplate "templates/default.html" defaultContext
        >>= relativizeUrls

  match "posts/**.md" $ do
    route $ setExtension "html"
    compile $
      pandocCompilerWithTransform myReaderOptions myWriterOptions (myTransformOptions cfg)
        >>= loadAndApplyTemplate "templates/post.html" postCtx
        >>= loadAndApplyTemplate "templates/default.html" postCtx
        >>= relativizeUrls

  create ["archive.html"] $ do
    route idRoute
    compile $ do
      posts <- recentFirst =<< loadAll "posts/**"
      categoryItems <- traverse makeItem (makeCategories categories)
      let archiveCtx =
            listField "posts" postCtx (pure posts)
              <> listField "categories" (categoryCtx categories) (pure categoryItems)
              <> constField "title" "Archives"
              <> constField "description" (T.unpack $ cfgDefaultDescription cfg)
              <> defaultContext

      makeItem ""
        >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
        >>= loadAndApplyTemplate "templates/default.html" archiveCtx
        >>= relativizeUrls

    tagsRules categories $ \cat pattern -> do
      let title = humanizeSlug cat
      route idRoute
      compile $ do
        posts <- recentFirst =<< loadAll pattern
        let ctx =
              constField "title" title
                <> listField "posts" postCtx (pure posts)
                <> constField "description" (T.unpack $ cfgDefaultDescription cfg)
                <> defaultContext
        makeItem ""
          >>= loadAndApplyTemplate "templates/category.html" ctx
          >>= loadAndApplyTemplate "templates/default.html" ctx
          >>= relativizeUrls

  match "index.html" $ do
    route idRoute
    compile $ do
      posts <- recentFirst =<< loadAll "posts/**"
      categoryItems <- traverse makeItem (makeCategories categories)
      let indexCtx =
            listField "posts" postCtx (pure posts)
              <> listField "categories" (categoryCtx categories) (pure categoryItems)
              <> defaultContext

      getResourceBody
        >>= applyAsTemplate indexCtx
        >>= loadAndApplyTemplate "templates/default.html" indexCtx
        >>= relativizeUrls

  match "templates/*" $ compile templateBodyCompiler

  match "room.md" $ do
    route $ setExtension "html"
    compile $ do
      pandocCompilerWithTransform myReaderOptions myWriterOptions (myTransformOptions cfg)
        >>= loadAndApplyTemplate "templates/default.html" defaultContext
        >>= relativizeUrls

  match (fromList ["manifest.json", "favicon.ico"]) $ do
    route idRoute
    compile $ copyFileCompiler

  match "static/**" $ do
    route idRoute
    compile $ copyFileCompiler

  elmDeps <- makePatternDependency KindContent ("src/**.elm" .||. "elm.json")

  rulesExtraDependencies [elmDeps] $ do
    match "src/Main.elm" $ do
      route $ constRoute "js/app.js"
      compile $ elmMakeCompiler ["--optimize"]
