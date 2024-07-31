import "./globals.css";
import Navbar from "$components/navbar";
import type { Metadata } from "next";
import Stars from "@/components/stars";

export const metadata: Metadata = {
  title: "Ivan Dimitrov",
  description: "Freelance Software Developer",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <Stars />
        <main>
          <Navbar />
          {children}
        </main>
      </body>
    </html>
  );
}
