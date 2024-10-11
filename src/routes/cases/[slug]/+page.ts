import type { LoadProperties } from "@sveltejs/kit";

export async function load({ params }: LoadProperties<Record<string, any>>) {
  const post = await import(`../${params.slug}.svx`);
  const { title, date } = post.metadata;
  const content = post.default;
  return {
    content,
    title,
    date
  }
}
