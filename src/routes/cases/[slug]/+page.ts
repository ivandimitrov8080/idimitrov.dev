import type { LoadProperties } from "@sveltejs/kit";

export async function load({ params }: LoadProperties<Record<string, any>>) {
  const post = await import(`../${params.slug}.svx`);
  const { title, date, author, published } = post.metadata;
  const content = post.default;
  const headers = [] as any;
  return {
    content,
    title,
    date,
    author,
    published,
    headers
  };
}
