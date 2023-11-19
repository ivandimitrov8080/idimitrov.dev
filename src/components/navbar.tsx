"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";

const Navbar = () => {
  const path = usePathname();
  const link = (text: string, href: string) => {
    return (
      <Link className="gradient w-full h-max rounded-md border-2" aria-label={text} href={href}>
        <div data-selected={path === href} className="btn data-[selected=true]:opacity-80">
          {text}
        </div>
      </Link>
    );
  };
  return (
    <div className="w-max h-max px-6 py-2 mx-auto rounded-full bg-slate-900 grid place-content-center">
      <div className="flex flex-row gap-6">
        {link("Home", "/")}
        {link("Cases", "/cases")}
        {link("Contact", "/contact")}
      </div>
    </div>
  );
};

export default Navbar;
