"use client";
import Link from "next/link";

const Navbar = () => {
  const home = (text: string, href: string) => {
    return (
      <Link className="text-md lg:text-2xl font-bold z-50" aria-label={text} href={href}>
        <span className="text-center">[{text}]</span>
      </Link>
    );
  };
  const link = (text: string, href: string) => {
    return (
      <Link className="w-max px-4 py-1 lg:px-10 rounded-full border-[1px] border-amber-50 box-border z-50" aria-label={text} href={href}>
        <span className="text-center">{text}</span>
      </Link>
    );
  };
  return (
    <nav className="p-12">
      <div className="flex flex-row justify-between box-border w-full h-8 z-40">
        {home("idimitrov.dev", "/")}
        {link("Contact", "/contact")}
      </div>
    </nav>
  );
};

export default Navbar;
