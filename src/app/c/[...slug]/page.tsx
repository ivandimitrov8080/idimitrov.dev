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
import { Metadata } from "next";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faCircleUser, faUserCircle } from "@fortawesome/free-solid-svg-icons";

type Params = {
  slug: string[];
};

type Props = {
  params: Params;
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { data } = getContent(params.slug);
  return {
    title: data.title,
    description: data.goal || "Software development notes",
  };
}

export async function generateStaticParams(): Promise<Params[]> {
  return getAllPaths().map(p => ({ slug: p.split("/") }));
}

export default function Content({ params }: Props) {
  const imgSize = 1024;
  const { data, content } = getContent(params.slug);

  if (data.draft) {
    notFound();
  }

  return (
    <div className="overflow-y-scroll grid justify-items-center">
      <div className="grid gap-20 grid-cols-12 w-11/12">
        <div className="col-span-8">
          <div className="flex flex-col gap-4 pl-24 pt-20">
            <h1 className="text-5xl font-bold">{data.title}</h1>
            <div className="flex flex-row gap-4">
              <FontAwesomeIcon className="w-14 h-14 hover:filter-none" icon={faCircleUser} />
              <div className="flex flex-col">
                <h1 className="font-bold text-xl">{data.author}</h1>
                <span className="text-xs text-neutral-400">Published {data.date}</span>
              </div>
            </div>
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
                    <Link className={className ?? ""} aria-label={getText(children)} href={href!} target="_blank">
                      {children}
                    </Link>
                  );
                },
                pre({ children, className }) {
                  return (
                    <div className="relative">
                      <CopyButton text={getText(children)} />
                      <pre className={`${className || ""} bg-gray-900`}>{children}</pre>
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
          </div>
        </div>
        <div className="h-screen col-span-4 py-64">
          <div className="grid gap-4 pl-12">
            <span className="text-2xl font-bold">Table of contents</span>
            <div className="circle-gradient w-full h-[1px] top-1/2"></div>
            <Link href="#" className="hover:gradient p-2 rounded-md">
              Technical details
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}
