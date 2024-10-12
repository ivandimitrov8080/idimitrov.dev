import type { LoadProperties } from "@sveltejs/kit";
import type { MetaTagsProps } from "svelte-meta-tags";

export async function load({ params }: LoadProperties<Record<string, any>>) {
  const post = await import(`../${params.slug}.svx`);
  const { title, date, author, published, goal, headers = [] } = post.metadata;
  const content = post.default;
  const pageMetaTags = Object.freeze({
    title: title,
    description: goal,
    openGraph: {
      title: title,
      description: goal
    }
  }) satisfies MetaTagsProps;
  return {
    content,
    title,
    goal,
    date,
    author,
    published,
    headers,
    pageMetaTags
  };
}
