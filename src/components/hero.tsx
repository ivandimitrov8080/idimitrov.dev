import Links from "./links";

const Hero = () => (
  <div className="grid px-14 py-48 gap-12">
    <div className="w-1/2">
      <p className="text-3xl text-[#FB923C]">Software Developer</p>
      <p className="text-8xl text-white capitalize">Full stack web development</p>
      <p className="text-8xl capitalize text-transparent font-bold bg-gradient-to-br from-transparent via-red-400 to-yellow-400 bg-clip-text">optimized</p>
    </div>
    <Links />
  </div>
)

export default Hero;
