import * as React from "react"
import Link from "next/link"
import { ArrowLeft, Share2, Star, CheckCircle, ChefHat, ChevronRight } from "lucide-react"
import { Header } from "@/components/home/Header"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"

export default function ChefDetailPage() {
  return (
    <div className="min-h-screen bg-background text-foreground antialiased pb-24 md:pb-12">
      {/* Top Header */}
      <Header />

      <main className="pt-24 md:pt-32 px-6 md:px-12 max-w-7xl mx-auto w-full">
        {/* Navigation & Action Header */}
        <div className="flex items-center justify-between mb-6">
          <Link
            href="/"
            className="flex items-center gap-2 text-sm font-semibold text-foreground hover:opacity-80 transition-opacity"
          >
            <ArrowLeft className="w-4 h-4" /> Back to Explore
          </Link>
          <button className="p-2 rounded-full hover:bg-muted transition-colors">
            <Share2 className="w-5 h-5 text-foreground" />
          </button>
        </div>

        {/* Bento Image Gallery */}
        <div className="grid grid-cols-1 md:grid-cols-4 grid-rows-2 gap-3 h-[360px] md:h-[500px] rounded-2xl overflow-hidden mb-12 shadow-sm">
          <div className="md:col-span-2 md:row-span-2 relative overflow-hidden">
            <img
              src="https://lh3.googleusercontent.com/aida-public/AB6AXuAJZXVqfkv9fKvZCsdUi2Bxr3s9CwyTufeVB_W3PS6Id7OqaVmo1JMvMObyDjU7yGhnPoVaLEjSVS62E-5kzbB-zUyeiI1HF8yXGIuCVYZoFp7q0ihfiTsOOrZp8OQWUPGPXBttxV6-DAXw7my_uRLLNEFhdYo5SvhSMZcNrKks3XM90ynbeLnO0EcJxI1bzsx11Kc7Pw0dMKEwqLydHYNj6IqbgabtKiWhXrSgI4GitVdzD2XlHIn5"
              alt="Truffle pasta"
              className="w-full h-full object-cover hover:scale-105 transition-transform duration-700"
            />
          </div>
          <div className="hidden md:block md:col-span-1 md:row-span-1 relative overflow-hidden">
            <img
              src="https://lh3.googleusercontent.com/aida-public/AB6AXuA3tJ1a_HwsIPZ3OIOg53YlnNaOgnZbOIQDksiDGQytuEMxpXV9Iaa2QpYzVPIFzb6M4QbWeO4P6Ezl6rZ1iar_HuQOBd1teSmtFvfYg8Bj14vL4W2lMxuTyWwYE2_y8OTYv19vvapgPNXKSbhEomgx3VOuLLJq3lyxbtiHjpbr2EMJNGWpJr-KhA18lqwas4QJuvoAjbTmie9kAYsqEW9x_lVfi8sQAtdqqWNstwAoacUS1Glm40-B"
              alt="Scallop appetizer"
              className="w-full h-full object-cover hover:scale-105 transition-transform duration-700"
            />
          </div>
          <div className="hidden md:block md:col-span-1 md:row-span-1 relative overflow-hidden">
            <img
              src="https://lh3.googleusercontent.com/aida-public/AB6AXuAr2H-6SvyZXBMxdCW8J5HaD2R2D5F8FD4qqKv7nKJaMbdirLVLMl3bIY_VtJaoXgIidJ0OrwJxC9IjgmQm6_MHG1fM_zWom6lfjrzbZZ5sJkzeBu-d9U6FnKdEEv0U7lKQbUgbSvXMfaVpp-B1Ag7dVQTyVOt_Zr7J-_0unjNmIsnyfpo8vfEsh4VlvfJsp_LDCB-rcCGnCSFhyROFebZV1hUHw57Rw4w7-XbdrS1mWR94rnDpn7Rh"
              alt="Fine wine pairing"
              className="w-full h-full object-cover hover:scale-105 transition-transform duration-700"
            />
          </div>
          <div className="hidden md:block md:col-span-2 md:row-span-1 relative overflow-hidden">
            <img
              src="https://lh3.googleusercontent.com/aida-public/AB6AXuCj-_meqOjvS96k5kGLumT5h4Lv5t90N4aNlsrH7yCM42rtnWKenS0dH-ShaZNoYY5gkdbyYLD7y7J6n_TQ1909H0rZWnIrGmtTfet9MApqyChQoTw12fWGkLc2s3BanPpBZormEzDs4Ns31LGv8ZbBPOGXGv8hWNgp8ivy-1XyetWH9qAmW2yE7EaKpFz4xzbctFTaE8ujPVy8_WXoxBIdwouhzpW-oAS_uLxqFFFzefbmhaqeIKGm"
              alt="Fresh ingredients"
              className="w-full h-full object-cover hover:scale-105 transition-transform duration-700"
            />
          </div>
        </div>

        {/* Content Layout */}
        <div className="grid grid-cols-1 md:grid-cols-12 gap-12">
          {/* Left Column: Chef Info & Menus */}
          <div className="md:col-span-8 space-y-8">
            {/* Chef Profile Header */}
            <div className="flex items-start justify-between border-b border-border pb-8">
              <div>
                <h1 className="font-serif text-3xl md:text-4xl font-bold text-foreground mb-3">
                  Chef Marco
                </h1>
                <div className="flex items-center gap-4 text-sm">
                  <span className="flex items-center gap-1 font-bold text-foreground">
                    <Star className="w-4 h-4 fill-secondary text-secondary" /> 4.8
                  </span>
                  <span className="text-muted-foreground">(124 reviews)</span>
                  <Badge variant="secondary" className="flex items-center gap-1">
                    <CheckCircle className="w-3 h-3 text-secondary" /> Verified
                  </Badge>
                </div>
              </div>
              <img
                src="https://lh3.googleusercontent.com/aida-public/AB6AXuCONoMmOXp0IjymBppcR4QkB6xr80XfagXEBCa0yI1Zt4NWfpJb6dPtzzSmAeUJCZ0UEdd9SEP-anJt2rq_REq4HHH3-K8902WrCKTp-oJluokeNMEJ8w5jKPmGBUZtB0bF9sTCTsBrvbCy2HVMAgcS2n4DSFhUG_gDEO1kbjiiDRKcw16uXYIwjsQE1rioTL1bVJW-635g42PTmwpQTKvuOc7jB-TrTegTDa_K8FhG5mF0rMFZXsHr"
                alt="Chef Marco"
                className="w-20 h-20 rounded-full object-cover shadow-sm"
              />
            </div>

            {/* About */}
            <div className="border-b border-border pb-8">
              <h2 className="font-serif text-2xl font-bold mb-4">About the Chef</h2>
              <p className="text-muted-foreground leading-relaxed text-base">
                Italian Michelin-star background, specializing in truffle pasta and contemporary Mediterranean cuisine. Chef Marco brings the warmth of a rustic Italian kitchen combined with the precision of high-end gastronomy directly to your dining room.
              </p>
              <div className="flex gap-2 mt-4">
                <Badge variant="outline">Italian</Badge>
                <Badge variant="outline">Fine Dining</Badge>
                <Badge variant="outline">Pasta Expert</Badge>
              </div>
            </div>

            {/* Menus Section */}
            <div className="space-y-6">
              <h2 className="font-serif text-2xl font-bold">Curated Menus</h2>

              {/* Menu Item 1 */}
              <div className="bg-card border border-border p-6 rounded-2xl shadow-sm flex flex-col md:flex-row justify-between items-start md:items-center gap-4 hover:-translate-y-0.5 transition-transform">
                <div>
                  <h3 className="font-bold text-lg text-foreground">The Truffle Experience (3-Course)</h3>
                  <p className="text-sm text-muted-foreground mt-1 mb-3">A curated journey through Northern Italy focusing on seasonal truffles.</p>
                  <span className="text-xs font-bold text-secondary uppercase tracking-wider">Most Popular</span>
                </div>
                <div className="flex flex-col items-end shrink-0 w-full md:w-auto">
                  <span className="font-serif text-2xl font-bold">$120<span className="text-sm font-normal text-muted-foreground">/pp</span></span>
                  <Button variant="outline" className="mt-3 w-full md:w-auto">View Menu</Button>
                </div>
              </div>

              {/* Menu Item 2 */}
              <div className="bg-card border border-border p-6 rounded-2xl shadow-sm flex flex-col md:flex-row justify-between items-start md:items-center gap-4 hover:-translate-y-0.5 transition-transform">
                <div>
                  <h3 className="font-bold text-lg text-foreground">Grand Tasting (5-Course)</h3>
                  <p className="text-sm text-muted-foreground mt-1">An expansive culinary exploration including seafood, pasta, and premium wagyu.</p>
                </div>
                <div className="flex flex-col items-end shrink-0 w-full md:w-auto">
                  <span className="font-serif text-2xl font-bold">$185<span className="text-sm font-normal text-muted-foreground">/pp</span></span>
                  <Button variant="outline" className="mt-3 w-full md:w-auto">View Menu</Button>
                </div>
              </div>
            </div>
          </div>

          {/* Right Column: Sticky Booking Card */}
          <div className="md:col-span-4">
            <div className="sticky top-32 bg-card border border-border rounded-2xl p-6 shadow-md space-y-6">
              <div className="flex items-baseline gap-2 border-b border-border pb-4">
                <span className="font-serif text-3xl font-bold">From $120</span>
                <span className="text-sm text-muted-foreground">/ person</span>
              </div>

              <div className="space-y-4">
                <div className="border border-border p-3 rounded-lg flex justify-between items-center cursor-pointer hover:border-secondary transition-colors">
                  <div>
                    <div className="text-xs font-bold uppercase text-muted-foreground">Date</div>
                    <div className="text-sm font-medium mt-0.5">Select date</div>
                  </div>
                </div>
                <div className="border border-border p-3 rounded-lg flex justify-between items-center cursor-pointer hover:border-secondary transition-colors">
                  <div>
                    <div className="text-xs font-bold uppercase text-muted-foreground">Guests</div>
                    <div className="text-sm font-medium mt-0.5">2 guests</div>
                  </div>
                </div>
              </div>

              <Button className="w-full py-6 text-base font-bold rounded-xl">
                Reserve Now
              </Button>
              <p className="text-xs text-center text-muted-foreground">You won't be charged yet</p>
            </div>
          </div>
        </div>
      </main>
    </div>
  )
}
