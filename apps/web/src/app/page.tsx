import * as React from "react"
import { Header } from "@/components/home/Header"
import { CategoryScroll } from "@/components/home/CategoryScroll"
import { HeroBanner } from "@/components/home/HeroBanner"
import { RecommendedChefs } from "@/components/home/RecommendedChefs"
import { TopMixologists } from "@/components/home/TopMixologists"
import { MobileBottomNav } from "@/components/home/MobileBottomNav"

export default function HomePage() {
  return (
    <div className="min-h-screen bg-background text-foreground antialiased pb-24 md:pb-12">
      {/* Sticky Header */}
      <Header />

      {/* Main Container */}
      <main className="pt-24 md:pt-32 px-6 md:px-12 max-w-7xl mx-auto w-full flex flex-col gap-10 md:gap-16">
        {/* Categories Bar */}
        <CategoryScroll />

        {/* Hero Section */}
        <HeroBanner />

        {/* Recommended Chefs */}
        <RecommendedChefs />

        {/* Top Mixologists */}
        <TopMixologists />
      </main>

      {/* Mobile Bottom Navigation */}
      <MobileBottomNav />
    </div>
  )
}
