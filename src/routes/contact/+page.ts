import type { MetaTagsProps } from "svelte-meta-tags";

export const load = async () => {
  const pageMetaTags = Object.freeze({
    title: 'Contact',
    description: 'Contact page',
    openGraph: {
      title: 'Contact',
      description: 'Contact page'
    }
  }) satisfies MetaTagsProps;
  return {
    pageMetaTags
  }
}
