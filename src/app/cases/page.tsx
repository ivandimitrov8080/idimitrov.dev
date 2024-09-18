import Link from "next/link";
import { getCases } from "$lib/content";

const CasesPage = () => {
  const cases = getCases()
    .filter(c => !c.data.draft)
    .sort((a, b) => Number(b.data.z) - Number(a.data.z))
    .map(c => c.data);
  return (
    <div className="overflow-y-scroll">
      <div className="relative grid lg:grid-cols-4 mx-8 lg:mt-44 lg:mx-44 gap-0">
        <div className="absolute hidden lg:block circle-gradient w-[1px] h-full right-1/2"></div>
        <div className="absolute hidden lg:block circle-gradient w-[1px] h-full right-1/4"></div>
        <div className="absolute hidden lg:block circle-gradient w-[1px] h-full left-1/4"></div>
        {cases.map((d, i) => (
          <div key={d.slug} className="aspect-[6/5] hover:gradient">
            <Link className="grid w-full h-full gap-4 lg:p-9" href={d.slug}>
              <span className="text-2xl lg:text-3xl line-clamp-3 self-center">{d.title}</span>
              <span className="text-xs text-gray-400">{d.date}</span>
            </Link>
            {i % 4 === 0 && i !== cases.length - 1 && <div className="absolute hidden lg:block circle-gradient w-full h-[1px]"></div>}
            {i !== cases.length - 1 && <div className="absolute lg:hidden circle-gradient w-full h-[1px]"></div>}
          </div>
        )
        )}
      </div>
    </div>
  )
};

export default CasesPage;
