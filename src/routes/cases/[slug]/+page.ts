import type { LoadProperties } from "@sveltejs/kit";
import type { MetaTagsProps } from "svelte-meta-tags";
// <MetaTags
//   {title}
//   titleTemplate="%s | idimitrov.dev"
//   description={goal}
//   canonical={$page.url.href}
//   openGraph={{
//     type: "website",
//     locale: "en_GB",
//     title: "idimitrov.dev",
//     description: "Software Development",
//     siteName: "idimitrov.dev"
//   }}
// />

export async function load({ params }: LoadProperties<Record<string, any>>) {
  const post = await import(`../${params.slug}.svx`);
  const { title, date, author, published, goal } = post.metadata;
  const content = post.default;
  const headers = [] as any;
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
