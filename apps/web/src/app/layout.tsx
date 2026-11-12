import type { Metadata } from "next";
import "@fontsource-variable/dm-sans";
import "@fontsource-variable/lora";
import "@fontsource-variable/cormorant-garamond";
import { AuthProvider } from "@/lib/auth-context";
import "./globals.css";

export const metadata: Metadata = {
  title: "GastroHost | Evde Özel Şef & Barmen Pazar Yeri",
  description:
    "Evde özel yemek deneyimleri, profesyonel şefler ve miksolojistler için güvenli Escrow ödeme garantili pazar yeri platformu.",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="tr" className="h-full antialiased">
      <body className="min-h-full flex flex-col bg-background text-foreground font-sans">
        <AuthProvider>{children}</AuthProvider>
      </body>
    </html>
  );
}
