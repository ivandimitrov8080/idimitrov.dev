import { GrayMatterFile } from "gray-matter";
import Link from "next/link";
import { getCases } from "../lib/content";

export default function Cases() {
  const cases: GrayMatterFile<string>[] = getCases()
  return (
    <div className="p-20 w-3/4 mx-auto">
      {cases.map((c) => {
        const d = c.data;
        const date = d.date.split("-")
        const from = date[0]?.trim()
        const to = date[1]?.trim()
        return (
          <div key={d.slug} className="w-full h-max flex justify-center">
            <Link className="btn flex flex-col w-full text-center" href={d.slug}>
              <span className="text-lg px-6">{d.title}</span>
              {from} {to ? `- ${to}` : ""}
            </Link>
          </div>
        )
      })}
    </div>
  )
}
