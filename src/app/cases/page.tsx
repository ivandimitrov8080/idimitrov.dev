import Link from "next/link";
import { getCases } from "$lib/content";

const CasesPage = () => {
  const cases = getCases().filter(c => !c.data.draft)
  return (
    <div className="overflow-y-scroll">
      <div className="relative grid grid-cols-4 mt-44 mx-44 gap-0">
        <div className="absolute circle-gradient w-[1px] h-full right-1/2"></div>
        <div className="absolute circle-gradient w-[1px] h-full right-1/4"></div>
        <div className="absolute circle-gradient w-[1px] h-full left-1/4"></div>
        {cases
          .sort((a, b) => Number(b.data.z) - Number(a.data.z))
          .map(c => c.data)
          .map((d, i) => {
            console.log(i, cases.length)
            return <div key={d.slug} className="aspect-[6/5] hover:gradient">
              <Link className="flex flex-col w-full h-full text-center" href={d.slug}>
                <span className="text-lg px-6">{d.title}</span>
                <span>{d.date}</span>
              </Link>
              {i % 4 === 0 && i !== cases.length - 1 && <div className="absolute circle-gradient w-full h-[1px]"></div>}
            </div>
          }
          )}
      </div>
    </div>
  )
};

export default CasesPage;
