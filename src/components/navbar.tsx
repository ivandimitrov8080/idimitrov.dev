"use client";
import Link from "next/link";

const Navbar = () => {
  const home = (text: string, href: string) => {
    return (
      <Link className="text-md lg:text-2xl font-bold" aria-label={text} href={href}>
        <span className="text-center">
          [{text}]
        </span>
      </Link>
    );
  };
  const link = (text: string, href: string) => {
    return (
      <Link className="w-max py-1 px-4 lg:py-2 lg:px-10 rounded-full border-[1px] border-amber-50" aria-label={text} href={href}>
        <span className="text-center">
          {text}
        </span>
      </Link>
    );
  };
  return (
    <div className="w-full h-8 px-4 py-12 lg:px-14 lg:py-8 z-50">
      <div className="flex flex-row gap-6 float-left">
        {home("idimitrov.dev", "/")}
      </div>
      <div className="flex flex-row gap-6 float-right">
        {link("Contact", "/contact")}
      </div>
    </div>
  );
};

export default Navbar;
