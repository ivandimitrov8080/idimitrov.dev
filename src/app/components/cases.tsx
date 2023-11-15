import Link from "next/link";
import { getCases } from "../lib/content";

const Cases = () =>
  <div className="p-20 w-3/4 mx-auto flex flex-col gap-4">
    {getCases().filter(c => !c.data.draft).sort(c => Number(c.data.z)).map((c) => c.data).map((d) =>
      <div key={d.slug} className="w-full h-max flex justify-center rounded-lg border-2">
        <Link className="btn flex flex-col w-full text-center" href={d.slug}>
          <span className="text-lg px-6">{d.title}</span>
          <span>{d.date}</span>
        </Link>
      </div>
    )}
  </div>
export default Cases;
