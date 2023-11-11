import { getAllPaths, getContent } from "$lib/content";
import Markdown from "react-markdown";
import remarkGfm from "remark-gfm";
import remarkFrontmatter from "remark-frontmatter";
import styles from "./content.module.css"
import Image from "next/image";
import rehypeRaw from "rehype-raw";
import rehypeHighlight from "rehype-highlight";

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

  const title = () => {
    return (
      <span className="text-3xl">
        {data.title}
      </span>
    )
  }
  const goal = () => {
    const g = data.goal
    return g ?
      (
        <div>
          <h2>The goal</h2>
          {g}
        </div>
      ) :
      ""
  }
  const role = () => {
    const r = data.role
    return r ?
      (
        <div>
          <h2>My role</h2>
          {r}
        </div>
      ) :
      ""
  }

  const ctnt = () => {
    return (
      <Markdown
        className={styles.md}
        remarkPlugins={[remarkGfm, remarkFrontmatter]}
        rehypePlugins={[rehypeRaw, rehypeHighlight]}
        components={{
          img({ height, width, src, alt }) {
            return (
              <span className="w-full h-max p-20">
                <Image className="w-full h-full" alt={alt!} height={Number(height) || imgSize} width={Number(width) || imgSize} src={`${data.slug}${src}`}></Image>
              </span>
            )
          }
        }}
      >
        {content}
      </Markdown>
    )
  }
  return (
    <div className="w-full h-full p-20 overflow-x-hidden overflow-scroll">
      <div className="flex flex-col gap-4 text-center">
        {title()}
        {goal()}
        {role()}
      </div>
      <div className="w-3/4 m-auto">
        {ctnt()}
      </div>
    </div>
  )
}
