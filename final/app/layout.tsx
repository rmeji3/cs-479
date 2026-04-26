import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import { SerialProvider } from "@/context/SerialContext";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "CycleWatch",
  description: "Bike wearable · live sensor dashboard",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="en"
      className={`${geistSans.variable} ${geistMono.variable} h-full antialiased`}
    >
      <body className="min-h-full flex flex-col">
        <SerialProvider>{children}</SerialProvider>
      </body>
    </html>
  );
}
