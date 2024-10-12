import type { LoadProperties } from '@sveltejs/kit';
import type { MetaTagsProps } from 'svelte-meta-tags'
export const prerender = true;
export const csr = false;

export const load = ({ url }: LoadProperties<Record<string, any>>) => {
  const baseMetaTags = Object.freeze({
    title: 'Home',
    titleTemplate: '%s | idimitrov.dev',
    description: 'Software Development',
    canonical: new URL(url.pathname, url.origin).href,
    openGraph: {
      type: 'website',
      url: new URL(url.pathname, url.origin).href,
      locale: 'en_GB',
      title: 'idimitrov.dev',
      description: 'Software Development',
      siteName: 'idimitrov.dev',
      images: [
        // {
        //   url: 'https://www.example.ie/og-image.jpg',
        //   alt: 'Og Image Alt',
        //   width: 800,
        //   height: 600,
        //   secureUrl: 'https://www.example.ie/og-image.jpg',
        //   type: 'image/jpeg'
        // }
      ]
    }
  }) satisfies MetaTagsProps;
  return {
    baseMetaTags
  };
};
