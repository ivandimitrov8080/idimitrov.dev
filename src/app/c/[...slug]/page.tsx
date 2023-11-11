import { getAllPaths, getContent } from "$lib/content";
import Markdown from "react-markdown";
import remarkGfm from "remark-gfm";
import remarkFrontmatter from "remark-frontmatter";
import styles from "./content.module.css"
import Image from "next/image";

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
  const imgSize = 1024;
  const { data, content } = getContent(params.slug);
  return (
    <div className="w-full h-full p-20 space-y-20">
      <div className="flex flex-col gap-4 text-center">
        <span className="text-3xl">
          {data.title}
        </span>
        <span>Goal: {data.goal}</span>
        <span>My role: {data.role}</span>
      </div>
      <Markdown className={styles.md} remarkPlugins={[remarkGfm, remarkFrontmatter]} components={{
        img({ height, width, src, alt }) {
          return (<Image alt={alt!} height={Number(height) || imgSize} width={Number(width) || imgSize} src={src!}></Image>)
        }
      }}>{content}</Markdown>
    </div>
  )
}
