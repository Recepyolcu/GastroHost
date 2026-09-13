import * as React from "react"
import { Button } from "@/components/ui/button"

export function HeroBanner() {
  return (
    <section className="relative w-full h-[420px] md:h-[500px] rounded-2xl overflow-hidden ambient-shadow group cursor-pointer">
      {/* Background Image */}
      <div
        className="absolute inset-0 bg-cover bg-center w-full h-full transition-transform duration-700 group-hover:scale-105"
        style={{
          backgroundImage: `url('https://lh3.googleusercontent.com/aida-public/AB6AXuDrWm9_kH_wWY63k9nHgX6YfxUXxi0uKRMrD22f-unKkAaqP-9Fb81T7f3QXF91nfQShUZjHbOSx4Jy1g_BOzVLsW-0-Ykh6Z3ZWXpcmV-1LPK6yDqQvAh6tX4PhPryF6G4_a8do59HQcSIiFWva55p-6I6U-9cmfVa7l6h3vJ747MMGJ7F-sWBQTCS2-eIDhCW8LI6B84NhfxiVvZ2cbgGZ5GIVk3bd1tQrAfp3oNJvBPnJS6uA9Pw')`,
        }}
      />
      {/* Overlay */}
      <div className="absolute inset-0 bg-gradient-to-t from-black/85 via-black/35 to-transparent" />

      {/* Content */}
      <div className="absolute bottom-0 left-0 p-6 md:p-12 w-full max-w-2xl text-white">
        <h1 className="font-serif text-3xl md:text-5xl font-bold leading-tight mb-3 drop-shadow-md">
          Elevate Your Home Dining
        </h1>
        <p className="text-sm md:text-lg text-white/90 mb-6 font-sans leading-relaxed">
          Discover bespoke culinary experiences curated by top professionals for your private events.
        </p>
        <Button variant="secondary" size="lg" className="font-semibold shadow-lg">
          Explore Experiences
        </Button>
      </div>
    </section>
  )
}
