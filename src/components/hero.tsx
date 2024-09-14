import Link from "next/link";
import Links from "./links";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faSquareArrowUpRight } from "@fortawesome/free-solid-svg-icons/faSquareArrowUpRight";

const Hero = () => (
  <div className="grid px-14 py-48 gap-12">
    <div className="w-1/2 grid gap-6">
      <div>
        <p className="text-3xl text-[#FB923C]">Software Developer</p>
        <p className="text-8xl text-white capitalize">Full stack web development</p>
        <p className="text-8xl capitalize text-transparent font-bold bg-gradient-to-br from-transparent via-teal-400 to-yellow-400 bg-clip-text">optimized</p>
      </div>
      <Link href="/cases" target="_blank" className="w-max">
        <div className="flex flex-row gap-0 w-max">
          <span className="rounded-full px-12 py-4 w-max gradient">Cases</span>
          <div className="w-6 h-8 m-[-15px] mt-3 gradient"></div>
          <span className="rounded-full px-4 py-4 w-max gradient">
            <FontAwesomeIcon className="w-6 h-6" icon={faSquareArrowUpRight} />
          </span>
        </div>
      </Link>
    </div>
    <Links />
  </div>
)

export default Hero;
