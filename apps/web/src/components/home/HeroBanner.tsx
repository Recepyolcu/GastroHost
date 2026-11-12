"use client";

import * as React from "react";
import Link from "next/link";
import { ShieldCheck, Sparkles, MapPin } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useAuth } from "@/lib/auth-context";

export function HeroBanner() {
  const { userLocation, setActiveCategory } = useAuth();

  return (
    <section className="relative w-full h-[400px] md:h-[460px] rounded-3xl overflow-hidden ambient-shadow group">
      {/* Background Image */}
      <div
        className="absolute inset-0 bg-cover bg-center w-full h-full transition-transform duration-700 group-hover:scale-105"
        style={{
          backgroundImage: `url('https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=1600&q=80')`,
        }}
      />
      {/* Overlay */}
      <div className="absolute inset-0 bg-gradient-to-t from-black/90 via-black/50 to-black/20" />

      {/* Content */}
      <div className="absolute bottom-0 left-0 p-6 md:p-12 w-full max-w-3xl text-white space-y-4">
        <div className="flex flex-wrap items-center gap-2">
          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-secondary/90 text-secondary-foreground text-xs font-bold shadow-sm">
            <Sparkles className="w-3.5 h-3.5" /> Evde Fine-Dining & Kokteyl Deneyimi
          </span>
          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-white/15 backdrop-blur-md text-white text-xs font-medium">
            <MapPin className="w-3.5 h-3.5 text-secondary" /> {userLocation.label}
          </span>
          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-500/20 backdrop-blur-md text-emerald-300 text-xs font-semibold">
            <ShieldCheck className="w-3.5 h-3.5" /> %100 Escrow Ödeme Güvencesi
          </span>
        </div>

        <h1 className="font-serif text-3xl md:text-5xl font-bold leading-tight drop-shadow-md">
          Evinizi Özel Bir Restorana Dönüştürün
        </h1>
        <p className="text-sm md:text-base text-white/90 font-sans leading-relaxed max-w-2xl">
          Kimlik ve adli sicil onaylı profesyonel şefler ile ödüllü miksolojistler; malzeme
          tedarikinden servis ve mutfak temizliğine kadar her detayı evinizde yönetir.
        </p>

        <div className="flex flex-wrap items-center gap-3 pt-2">
          <Button
            variant="secondary"
            size="lg"
            onClick={() => setActiveCategory("chef")}
            className="font-bold shadow-lg rounded-xl cursor-pointer"
          >
            Özel Şefleri İncele
          </Button>
          <Button
            variant="outline"
            size="lg"
            onClick={() => setActiveCategory("bartender")}
            className="font-semibold bg-white/10 hover:bg-white/20 text-white border-white/30 rounded-xl backdrop-blur-sm cursor-pointer"
          >
            Miksolojist & Barmen Ekle
          </Button>
          <Link href="/chef-dashboard" className="hidden sm:inline-block">
            <Button
              variant="ghost"
              size="lg"
              className="text-white/85 hover:text-white hover:bg-white/10 rounded-xl text-xs font-semibold"
            >
              Şef / Barmen Paneli →
            </Button>
          </Link>
        </div>
      </div>
    </section>
  );
}
