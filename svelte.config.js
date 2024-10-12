import adapter from '@sveltejs/adapter-static';
import rehypeSlug from 'rehype-slug';
import { mdsvex, escapeSvelte } from 'mdsvex';
import remarkGfm from 'remark-gfm';
import { sveltePreprocess } from 'svelte-preprocess';
import { createHighlighter } from 'shiki';
import { visit } from 'unist-util-visit'
import { toString } from 'mdast-util-to-string'
import GithubSlugger from 'github-slugger'

const theme = "github-dark"
const highlighter = await createHighlighter({
  themes: [theme],
  langs: ['javascript', 'typescript', 'tsx', "jsx", "bash", "console", "html"]
});

const slugs = new GithubSlugger()
function remarkSetHeaders() {
  return function(tree, file) {
    slugs.reset()
    const headers = []
    visit(tree, 'heading', function(node) {
      const text = toString(node);
      let h = {
        id: slugs.slug(toString(node)),
        text
      };
      headers.push(h)
    })
    file.data.fm.headers = headers;
  }
}

const config = {
  kit: {
    adapter: adapter({
      pages: 'build',
      assets: 'build',
      fallback: undefined,
      precompress: false,
      strict: true
    }),
  },
  extensions: [".svelte", ".svx"],
  preprocess: [
    sveltePreprocess(),
    mdsvex({
      rehypePlugins: [rehypeSlug],
      remarkPlugins: [remarkGfm, remarkSetHeaders],
      highlight: {
        highlighter: async (code, lang = 'text') => {
          const html = escapeSvelte(highlighter.codeToHtml(code, { lang, theme }));
          return `{@html \`${html}\` }`;
        }
      },
    })
  ],
};
export default config;
