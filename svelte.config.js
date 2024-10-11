import adapter from '@sveltejs/adapter-static';
import rehypeSlug from 'rehype-slug';
import { mdsvex, escapeSvelte } from 'mdsvex';
import remarkGfm from 'remark-gfm';
import { sveltePreprocess } from 'svelte-preprocess';
import { createHighlighter } from 'shiki';

const theme = "github-dark"
const highlighter = await createHighlighter({
  themes: [theme],
  langs: ['javascript', 'typescript', 'tsx', "jsx", "bash", "console", "html"]
});

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
      remarkPlugins: [remarkGfm],
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
