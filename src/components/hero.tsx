import Link from "next/link";
import Links from "./links";
import CasesSvg from "./cases-svg";

const Hero = () => (
  <div className="grid grid-cols-1 lg:grid-cols-2 px-14 py-48 gap-12 w-full h-full">
    <div className="grid gap-6">
      <div className="pt-12">
        <p className="text-xl lg:text-3xl text-[#FB923C]">Software Developer</p>
        <p className="text-4xl lg:text-8xl text-white capitalize">Full stack web development</p>
        <p className="text-4xl lg:text-8xl capitalize text-transparent font-bold bg-gradient-to-br from-transparent via-teal-400 to-yellow-400 bg-clip-text">Refined</p>
      </div>
      <Link aria-label="Cases" href="/cases" target="_blank" className="w-max">
        <CasesSvg />
      </Link>
      <div className="w-full h-[1px] circle-gradient"></div>
    </div>
    <Links />
    <div className="flex flex-row gap-12">
      <div>
        <p className="text-6xl text-white capitalize">10+</p>
        <p className="text-xl text-white capitalize">Clients worldwide</p>
      </div>
      <div>
        <p className="text-6xl text-white capitalize">30+</p>
        <p className="text-xl text-white capitalize">Projects done</p>
      </div>
    </div>
  </div>
)

export default Hero;
