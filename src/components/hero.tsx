import Link from "next/link";
import Links from "./links";
import CasesSvg from "./cases-svg";

const Hero = () => (
  <div className="grid grid-cols-1 lg:grid-cols-2 gap-7 lg:gap-0 w-full h-max p-7 lg:p-20 overflow-y-scroll lg:overflow-y-hidden">
    <div className="grid lg:gap-6 pb-12">
      <div className="pt-0 lg:pt-12">
        <p className="text-xl lg:text-3xl text-[#FB923C]">Software Developer</p>
        <p className="text-4xl lg:text-8xl text-white capitalize">Full stack web development</p>
        <p className="text-4xl lg:text-8xl capitalize text-transparent font-bold bg-gradient-to-br from-transparent via-teal-400 to-yellow-400 bg-clip-text">Refined</p>
      </div>
      <Link aria-label="Cases" href="/cases" target="_blank" className="w-max">
        <CasesSvg />
      </Link>
    </div>
    <Links />
    <div className="flex flex-col lg:gap-12">
      <div className="w-full h-[1px] circle-gradient hidden lg:block"></div>
      <div className="flex flex-row gap-12">
        <div>
          <p className="text-3xl lg:text-6xl text-white capitalize">10+</p>
          <p className="text-md lg:text-xl text-white capitalize">Clients worldwide</p>
        </div>
        <div>
          <p className="text-3xl lg:text-6xl text-white capitalize">30+</p>
          <p className="text-md lg:text-xl text-white capitalize">Projects done</p>
        </div>
      </div>
    </div>
  </div>
);

export default Hero;
