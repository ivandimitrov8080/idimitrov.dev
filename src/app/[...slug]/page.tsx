import { getAllPaths, getContent } from "$lib/content";
import Markdown from "react-markdown";
import remarkGfm from "remark-gfm";

type Params = {
  slug: string[]
}

type Props = {
  params: Params
}

export async function generateStaticParams(): Promise<Params[]> {
  return getAllPaths().map(p => ({ slug: p.split("/") }))
}

export default function Content({ params }: Props) {
  const content = getContent(params.slug)
  return (
    <main>
      <Markdown className="h-min" remarkPlugins={[remarkGfm]}>{content}</Markdown>
    </main>
  )
}
