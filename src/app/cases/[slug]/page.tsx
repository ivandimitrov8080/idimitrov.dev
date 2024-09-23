import { getContent, getCases, getHeaders } from "$lib/content";
import { notFound } from "next/navigation";
import Link from "next/link";
import { Metadata } from "next";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faCircleUser } from "@fortawesome/free-solid-svg-icons";
import MarkdownRenderer from "@/components/markdown-renderer";

type Params = {
  slug: string;
};

type Props = {
  params: Params;
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { data } = getContent(params.slug);
  return {
    title: data.title || "Note",
    description: data.goal || "Software development notes",
  };
}

export async function generateStaticParams(): Promise<Params[]> {
  return getCases().map(p => ({ slug: p.data.slug }));
}

export default function Content({ params }: Props) {
  const { data, content } = getContent(params.slug);

  if (data.draft) {
    notFound();
  }

  const headers = getHeaders(content);

  return (
    <div className="overflow-y-auto lg:grid lg:justify-items-center">
      <div className="lg:grid lg:gap-20 lg:grid-cols-12 lg:w-11/12">
        <div className="lg:col-span-9 p-4">
          <div className="flex flex-col gap-4 lg:pl-24 lg:pt-20">
            <h1 className="text-4xl lg:text-5xl font-bold">{data.title}</h1>
            <div className="flex flex-row gap-4">
              {data.author && data.published && (
                <>
                  <FontAwesomeIcon className="w-14 h-14 hover:filter-none" icon={faCircleUser} />
                  <div className="flex flex-col">
                    <h1 className="font-bold text-xl">{data.author}</h1>
                    <span className="text-xs text-neutral-400">Published {data.published}</span>
                  </div>
                </>
              )}
            </div>
            <MarkdownRenderer content={content} />
          </div>
        </div>
        <div className="hidden lg:block h-screen lg:col-span-3 py-64">
          <div className="fixed grid gap-4 pl-12">
            <span className="text-2xl font-bold">Table of contents</span>
            <div className="circle-gradient w-full h-[1px] top-1/2"></div>
            <div className="flex flex-col">
              {headers.map(h => (
                <Link key={h.id} href={`#${h.id}`} className="hover:gradient p-2 rounded-md">
                  {h.text}
                </Link>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
