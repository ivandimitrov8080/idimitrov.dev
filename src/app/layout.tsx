import "./globals.css";
import Navbar from "$components/navbar";
import type { Metadata } from "next";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faCakeCandles, faSquareFull } from "@fortawesome/free-solid-svg-icons";

export const metadata: Metadata = {
  title: "Ivan Dimitrov",
  description: "Freelance Software Developer",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  let today = new Date();
  return (
    <html lang="en">
      <body>
        <main>
          <Navbar />
          {children}
        </main>
      </body>
    </html>
  );
}
