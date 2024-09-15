import Link from "next/link";
import Links from "./links";
import CasesSvg from "./cases-svg";

const Hero = () => (
  <div className="grid px-14 py-48 gap-12">
    <div className="w-1/2 grid gap-6">
      <div>
        <p className="text-3xl text-[#FB923C]">Software Developer</p>
        <p className="text-8xl text-white capitalize">Full stack web development</p>
        <p className="text-8xl capitalize text-transparent font-bold bg-gradient-to-br from-transparent via-teal-400 to-yellow-400 bg-clip-text">optimized</p>
      </div>
      <Link aria-label="Cases" href="/cases" target="_blank" className="w-max">
        <CasesSvg />
      </Link>
      <div className="w-full h-[1px] circle-gradient"></div>
    </div>
    <Links />
  </div>
)

export default Hero;
