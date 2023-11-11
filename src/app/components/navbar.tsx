"use client"
import Link from "next/link";
import { usePathname } from "next/navigation";

const link = (text: string, href: string) => {
  const path = usePathname()
  return (
    <Link data-selected={path === href} className="btn" aria-label={text} href={href}>
      {text}
    </Link>
  )
}
const Navbar = () =>
  <div className="w-max h-max px-6 py-2 mx-auto rounded-full bg-slate-900 grid place-content-center">
    <div className="flex flex-row gap-6">
      {link("Home", "/")}
      {link("Cases", "/cases")}
      {link("Contact", "/contact")}
    </div>
  </div>

export default Navbar
