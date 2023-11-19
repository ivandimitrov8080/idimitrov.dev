import styles from "./content.module.css";
import { getAllPaths, getContent } from "$lib/content";
import Markdown from "react-markdown";
import remarkGfm from "remark-gfm";
import remarkFrontmatter from "remark-frontmatter";
import Image from "next/image";
import rehypeRaw from "rehype-raw";
import { notFound } from "next/navigation";
import Link from "next/link";
import CopyButton from "$components/copy-button";
import { getText } from "$lib/react";
import { Prism as SyntaxHighlighter } from "react-syntax-highlighter";
import codeStyle from "react-syntax-highlighter/dist/esm/styles/prism/coldark-dark";

type Params = {
  slug: string[];
};

type Props = {
  params: Params;
};

export async function generateStaticParams(): Promise<Params[]> {
  return getAllPaths().map(p => ({ slug: p.split("/") }));
}

export default function Content({ params }: Props) {
  const imgSize = 1024;
  const { data, content } = getContent(params.slug);

  if (data.draft) {
    notFound();
  }

  const title = () => <span className="text-3xl">{data.title}</span>;

  const goal = () =>
    data.goal ? (
      <div>
        <h2>The goal</h2>
        {data.goal}
      </div>
    ) : (
      ""
    );

  const role = () =>
    data.role ? (
      <div>
        <h2>My role</h2>
        {data.role}
      </div>
    ) : (
      ""
    );

  const date = () => (data.date ? <span>{data.date}</span> : "");

  const ctnt = () => (
    <Markdown
      className={styles.md}
      remarkPlugins={[remarkGfm, remarkFrontmatter]}
      rehypePlugins={[rehypeRaw]}
      components={{
        img({ height, width, src, alt, className }) {
          return (
            <span className="w-full h-max p-20">
              <Image
                className={`w-full h-full border-2 px-2 ${className || ""}`}
                alt={alt!}
                height={Number(height) || imgSize}
                width={Number(width) || imgSize}
                src={`${data.slug}${src}`}></Image>
            </span>
          );
        },
        a({ href, children, className }) {
          return (
            <Link className={className || ""} aria-label={getText(children)} href={href!} target="_blank">
              {children}
            </Link>
          );
        },
        pre({ children, className }) {
          return (
            <div className="relative">
              <CopyButton text={getText(children)} />
              <pre className={`${className || ""}`}>{children}</pre>
            </div>
          );
        },
        code({ children, ref, className, node, ...rest }) {
          const match = /language-(\w+)/.exec(className || "");
          return match ? (
            <SyntaxHighlighter {...rest} language={match[1]} style={codeStyle}>
              {getText(children)}
            </SyntaxHighlighter>
          ) : (
            <code {...rest} className={`${className} text-orange-400 font-black font-mono`}>
              {children}
            </code>
          );
        },
      }}>
      {content}
    </Markdown>
  );

  return (
    <div className="w-full h-full p-4 lg:p-20 overflow-x-hidden overflow-scroll">
      <div className="flex flex-col gap-4 text-center border-amber-50 border-2 p-2 m-2 lg:rounded-full">
        {title()}
        {goal()}
        {role()}
        {date()}
      </div>
      <div className="w-full m-auto lg:w-3/4 mt-10">{ctnt()}</div>
    </div>
  );
}
