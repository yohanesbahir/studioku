import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { SupportWidget } from "@/components/ui/support-widget";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "STUDIOKU | Platform Edit Foto, Desain & Video AI All-in-One",
  description: "Tingkatkan visual bisnismu.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="id">
      <body className={inter.className}>
        {children}
        <SupportWidget />
      </body>
    </html>
  );
}
