import Link from "next/link";
import { getCases, getCasesTest } from "$lib/content";

const CasesPage = () => {
  const cases = getCasesTest()
  const rows = Math.ceil(cases.length / 4);
  return (
    <div className="relative grid grid-cols-4 mt-44 mx-44 gap-0 overflow-y-scroll">
      <div className="absolute circle-gradient w-[1px] h-full right-1/2"></div>
      <div className="absolute circle-gradient w-[1px] h-full right-1/4"></div>
      <div className="absolute circle-gradient w-[1px] h-full left-1/4"></div>
      {Array.from(Array(rows).keys()).map(_i =>
        <div className="absolute circle-gradient w-full h-[1px] top-1/2"></div>
      )}
      {cases
        .filter(c => !c.data.draft)
        .sort((a, b) => Number(b.data.z) - Number(a.data.z))
        .map(c => c.data)
        .map(d => (
          <div key={d.slug} className="aspect-[6/5] hover:gradient">
            <Link className="flex flex-col w-full h-full text-center" href={d.slug}>
              <span className="text-lg px-6">{d.title}</span>
              <span>{d.date}</span>
            </Link>
          </div>
        ))}
    </div>
  )
};

export default CasesPage;
