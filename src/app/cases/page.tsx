import Link from "next/link";
import { getCases } from "$lib/content";

const CasesPage = () => (
  <div className="p-20 w-full h-full flex flex-col gap-4 overflow-y-scroll">
    {getCases()
      .filter(c => !c.data.draft)
      .sort((a, b) => Number(b.data.z) - Number(a.data.z))
      .map(c => c.data)
      .map(d => (
        <div key={d.slug} className="w-full lg:w-3/4 mx-auto h-max flex justify-center rounded-lg border-2">
          <div className="gradient w-full">
            <Link className="btn flex flex-col w-full text-center" href={d.slug}>
              <span className="text-lg px-6">{d.title}</span>
              <span>{d.date}</span>
            </Link>
          </div>
        </div>
      ))}
  </div>
);

export default CasesPage;
