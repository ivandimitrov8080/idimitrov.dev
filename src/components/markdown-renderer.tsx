import Markdown from "react-markdown";
import rehypeRaw from "rehype-raw";
import rehypeSlug from "rehype-slug";
import remarkGfm from "remark-gfm";
import Image from "next/image";
import CopyButton from "$components/copy-button";
import { getText } from "$lib/react";
import { Prism as SyntaxHighlighter } from "react-syntax-highlighter";
import codeStyle from "react-syntax-highlighter/dist/esm/styles/prism/coldark-dark";
import Link from "next/link";
import styles from "../app/c/[...slug]/content.module.css";

type MarkdownRendererProps = {
  data: { [key: string]: any }
  content: string
}

const MarkdownRenderer = ({ data, content }: MarkdownRendererProps) => {

  const imgSize = 1024;
  return (
    <Markdown
      className={styles.md}
      remarkPlugins={[remarkGfm]}
      rehypePlugins={[rehypeRaw, rehypeSlug]}
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
        h1({ children, id }) {
          return (
            <h1 id={id}>
              <Link href={`#${id}`}>{children}</Link>
            </h1>
          );
        },
        h2({ children, id }) {
          return (
            <h2 id={id}>
              <Link href={`#${id}`}>{children}</Link>
            </h2>
          );
        },
        h3({ children, id }) {
          return (
            <h3 id={id}>
              <Link href={`#${id}`}>{children}</Link>
            </h3>
          );
        },
        h4({ children, id }) {
          return (
            <h4 id={id}>
              <Link href={`#${id}`}>{children}</Link>
            </h4>
          );
        },
        h5({ children, id }) {
          return (
            <h5 id={id}>
              <Link href={`#${id}`}>{children}</Link>
            </h5>
          );
        },
        h6({ children, id }) {
          return (
            <h6 id={id}>
              <Link href={`#${id}`}>{children}</Link>
            </h6>
          );
        },
      }}>
      {content}
    </Markdown>
  )
}
export default MarkdownRenderer
