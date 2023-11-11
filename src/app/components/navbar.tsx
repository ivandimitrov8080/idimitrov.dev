"use client"
import Link from "next/link";
import { usePathname } from "next/navigation";
import { ReactNode } from "react";

export default function Navbar() {
  const path = usePathname()

  const link = (text: ReactNode, href: string) => {
    return (
      <Link aria-selected={path === href} className="btn" aria-label="Home" href={href}>
        {text}
      </Link>
    )
  }

  return (
    <div className="w-max h-max px-6 py-2 mx-auto rounded-full bg-slate-900 grid place-content-center">
      <div className="flex flex-row gap-6">
        {link("Home", "/")}
        {link("Cases", "/cases")}
        {link("Contact", "/contact")}
      </div>
    </div>
  )
}
