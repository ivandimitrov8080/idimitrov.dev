"use client"
import Link from "next/link";
import { usePathname } from "next/navigation";

export default function Navbar() {
  const path = usePathname()
  return (
    <div className="w-full h-max p-2 grid place-content-center">
      <div className="flex flex-row gap-6">
        <Link className={`btn ${path === "/" ? "btn-current" : ""}`} aria-label="Home" href="/">
          Home
        </Link>
        <Link className={`btn ${path === "/cases" ? "btn-current" : ""}`} aria-label="Cases" href="/cases">
          Cases
        </Link>
      </div>
    </div>
  )
}