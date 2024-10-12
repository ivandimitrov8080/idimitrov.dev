import { getCases } from "$lib/util/content";
import type { MetaTagsProps } from "svelte-meta-tags";

export const load = async () => {
  const pageMetaTags = Object.freeze({
    title: "Cases",
    description: "Development Case Studies",
    openGraph: {
      title: "Cases",
      description: "Development Case Studies"
    }
  }) satisfies MetaTagsProps;
  return {
    cases: await getCases(),
    pageMetaTags
  };
};
