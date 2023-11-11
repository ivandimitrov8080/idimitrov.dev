"use client"
import Link from "next/link";
import { usePathname } from "next/navigation";

export default function Navbar() {
  const path = usePathname()

  const link = (text: string, href: string) => {
    return (
      <Link aria-selected={path === href} className="btn" aria-label="Home" href={href}>
        {text}
      </Link>
    )
  }

  return (
    <div className="w-full h-max p-2 grid place-content-center">
      <div className="flex flex-row gap-6">
        {link("Home", "/")}
        {link("Cases", "/cases")}
        {link("Contact", "/contact")}
      </div>
    </div>
  )
}
