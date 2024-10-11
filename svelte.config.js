import adapter from '@sveltejs/adapter-static';
import rehypeSlug from 'rehype-slug';
import { mdsvex } from 'mdsvex';
import remarkGfm from 'remark-gfm';
import { sveltePreprocess } from 'svelte-preprocess';

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
      remarkPlugins: [remarkGfm]
    })
  ],
};
export default config;
