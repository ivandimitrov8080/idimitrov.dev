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
          {today.getDate() === new Date(today.getFullYear(), 12, 17).getDate() && (
            <div className="absolute bottom-14 right-14">
              <div className="flex flex-col">
                <FontAwesomeIcon mask={faSquareFull} className="w-20 h-20 text-neutral-950 bg-gradient-to-t from-slate-950 via-red-700 to-yellow-400" icon={faCakeCandles} />
                <span>It's my birthday.</span>
              </div>
            </div>
          )}
        </main>
      </body>
    </html>
  );
}
