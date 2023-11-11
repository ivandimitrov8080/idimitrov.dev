import './globals.css'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: "Ivan Dimitrov",
  description: "Freelance Software Developer",
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body>
        <main>
          {children}
        </main>
      </body>
    </html>
  )
}
