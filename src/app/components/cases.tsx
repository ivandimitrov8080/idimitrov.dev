import { GrayMatterFile } from "gray-matter";
import Link from "next/link";
import { getCases } from "../lib/content";

const cases: GrayMatterFile<string>[] = getCases()
const Cases = () =>
  <div className="p-20 w-3/4 mx-auto flex flex-col gap-4">
    {cases.filter(c => !c.data.draft).sort(c => c.data.z).map((c) => c.data).map((d) =>
      <div key={d.slug} className="w-full h-max flex justify-center">
        <Link className="btn flex flex-col w-full text-center" href={d.slug}>
          <span className="text-lg px-6">{d.title}</span>
          <span>{d.date}</span>
        </Link>
      </div>
    )}
  </div>
export default Cases;
