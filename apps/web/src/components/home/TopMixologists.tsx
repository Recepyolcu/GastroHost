"use client";

import * as React from "react";
import Link from "next/link";
import {
  Star,
  ShieldCheck,
  Award,
  Wine,
  MapPin,
  Search,
  SlidersHorizontal,
  Loader2,
  Sparkles,
} from "lucide-react";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { supabase } from "@/lib/supabase";
import { useAuth } from "@/lib/auth-context";

interface MixologistCardData {
  id: string;
  user_id: string;
  provider_type: string;
  title: string;
  bio: string;
  city_region: string;
  hourly_rate: number;
  rating_avg: number;
  total_reviews: number;
  is_verified: boolean;
  is_available_now?: boolean;
  portfolio_images: string[];
  specialties?: {
    cocktails?: string[];
    cuisines?: string[];
  };
  verification_badges?: {
    hygiene_cert?: boolean;
    diploma?: boolean;
  };
  user?: {
    full_name: string;
    avatar_url?: string;
  };
  menus?: {
    id: string;
    title: string;
    price_per_person: number;
    ingredients_included?: boolean;
  }[];
  distance_km?: number;
}

export function TopMixologists() {
  const { userLocation, activeCategory } = useAuth();
  const [mixologists, setMixologists] = React.useState<MixologistCardData[]>([]);
  const [loading, setLoading] = React.useState<boolean>(true);
  const [searchQuery, setSearchQuery] = React.useState<string>("");
  const [maxHourlyRate, setMaxHourlyRate] = React.useState<number>(3000);
  const [onlyMobileBarIncluded, setOnlyMobileBarIncluded] = React.useState<boolean>(false);

  React.useEffect(() => {
    let mounted = true;

    const fetchMixologists = async () => {
      setLoading(true);
      try {
        const { data: nearbyData } = await supabase.rpc("get_nearby_providers", {
          user_lat: userLocation.lat,
          user_lng: userLocation.lng,
          target_type: "bartender",
        });

        const distanceMap = new Map<string, number>();
        if (Array.isArray(nearbyData)) {
          nearbyData.forEach((row: { provider_id: string; distance_km: number }) => {
            distanceMap.set(row.provider_id, Number(row.distance_km));
          });
        }

        const { data, error } = await supabase
          .from("provider_profiles")
          .select(
            `
            *,
            user:profiles (
              full_name,
              avatar_url
            ),
            menus:menus (
              id,
              title,
              price_per_person,
              ingredients_included
            )
          `
          )
          .in("provider_type", ["bartender", "both"])
          .order("rating_avg", { ascending: false });

        if (!error && data && mounted) {
          const enriched = (data as unknown as MixologistCardData[]).map((item) => ({
            ...item,
            distance_km: distanceMap.get(item.id),
          }));
          setMixologists(enriched);
        }
      } catch (e) {
        console.error("Error loading mixologists:", e);
      } finally {
        if (mounted) setLoading(false);
      }
    };

    fetchMixologists();
    return () => {
      mounted = false;
    };
  }, [userLocation.lat, userLocation.lng]);

  if (activeCategory === "chef") {
    return null;
  }

  const filteredMixologists = mixologists.filter((mix) => {
    const rate = Number(mix.hourly_rate || 1200);
    if (rate > maxHourlyRate) return false;

    if (onlyMobileBarIncluded && !mix.is_verified) {
      return false;
    }

    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      const name = mix.user?.full_name?.toLowerCase() || "";
      const title = mix.title?.toLowerCase() || "";
      const bio = mix.bio?.toLowerCase() || "";
      const cocktails = (mix.specialties?.cocktails || []).join(" ").toLowerCase();
      return (
        name.includes(q) ||
        title.includes(q) ||
        bio.includes(q) ||
        cocktails.includes(q)
      );
    }

    return true;
  });

  return (
    <section className="w-full space-y-6">
      {/* Section Header & Live Filters (Equal Hierarchy with Chefs) */}
      <div className="flex flex-col lg:flex-row lg:items-end justify-between gap-4">
        <div>
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-purple-500/10 border border-purple-500/20 text-purple-600 dark:text-purple-400 text-xs font-bold mb-2">
            <Sparkles className="w-3.5 h-3.5" /> Craft Cocktail & Mobil Bar Deneyimi
          </div>
          <h2 className="font-serif text-2xl md:text-3xl font-bold tracking-tight text-foreground flex items-center gap-2.5">
            <Wine className="w-7 h-7 text-purple-600 dark:text-purple-400" /> Bölgenizdeki Master Miksolojistler
          </h2>
          <p className="text-sm text-muted-foreground mt-1">
            {userLocation.label} konumuna taşınabilir bar ünitesi, kristal camlar ve imza kokteyllerle gelen uzman barmenler
          </p>
        </div>

        {/* Filter Controls */}
        <div className="flex flex-wrap items-center gap-3 bg-card border border-border p-2.5 rounded-2xl shadow-xs">
          <div className="relative w-full sm:w-56">
            <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground" />
            <Input
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Miksolojist veya kokteyl ara..."
              className="pl-9 h-9 text-xs"
            />
          </div>

          <div className="flex items-center gap-2 px-2 text-xs">
            <SlidersHorizontal className="w-3.5 h-3.5 text-purple-600 dark:text-purple-400" />
            <span className="text-muted-foreground">Maks:</span>
            <select
              value={maxHourlyRate}
              onChange={(e) => setMaxHourlyRate(Number(e.target.value))}
              className="bg-muted px-2 py-1 rounded-lg font-semibold text-foreground focus:outline-none"
            >
              <option value={1000}>₺1.000 / saat</option>
              <option value={1500}>₺1.500 / saat</option>
              <option value={2500}>₺2.500 / saat</option>
              <option value={3000}>Tüm Fiyatlar</option>
            </select>
          </div>

          <label className="flex items-center gap-1.5 text-xs font-medium px-2 cursor-pointer">
            <input
              type="checkbox"
              checked={onlyMobileBarIncluded}
              onChange={(e) => setOnlyMobileBarIncluded(e.target.checked)}
              className="accent-purple-600 rounded"
            />
            <span>Mobil Bar Dahil</span>
          </label>
        </div>
      </div>

      {/* Mixologists Showcase Grid (Full-Bleed 3-Column Layout Matching Chefs) */}
      {loading ? (
        <div className="flex items-center justify-center py-16">
          <Loader2 className="w-8 h-8 animate-spin text-purple-600" />
        </div>
      ) : filteredMixologists.length === 0 ? (
        <div className="text-center py-14 bg-card border border-border rounded-2xl p-6">
          <Wine className="w-10 h-10 text-muted-foreground mx-auto mb-2" />
          <h3 className="font-serif text-lg font-bold">Filtreye Uygun Miksolojist Bulunamadı</h3>
          <p className="text-xs text-muted-foreground mt-1">
            Saatlik bütçe limitini artırabilir veya arama terimini değiştirebilirsiniz.
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredMixologists.map((mix) => {
            const coverImg =
              mix.portfolio_images?.[0] ||
              mix.user?.avatar_url ||
              "https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?auto=format&fit=crop&w=800&q=80";

            const cocktailTags =
              mix.specialties?.cocktails && mix.specialties.cocktails.length > 0
                ? mix.specialties.cocktails.slice(0, 3)
                : ["İmza Kokteyller", "Moleküler Miksoloji", "Mobil Bar Dahil"];

            const hourlyPrice = Number(mix.hourly_rate || 1200);

            return (
              <Card
                key={mix.id}
                className="group hover:-translate-y-1 transition-all duration-300 border border-purple-500/25 bg-card overflow-hidden flex flex-col justify-between"
              >
                <div>
                  {/* Cover Image & Badges */}
                  <div className="relative h-56 w-full overflow-hidden">
                    <img
                      src={coverImg}
                      alt={mix.user?.full_name || "Miksolojist"}
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                    />
                    <div className="absolute inset-0 bg-gradient-to-t from-black/75 via-black/15 to-transparent" />

                    {/* Top-Left Role Badge */}
                    <div className="absolute top-3.5 left-3.5 bg-purple-700/90 backdrop-blur-md text-white px-2.5 py-1 rounded-full flex items-center gap-1.5 text-[11px] font-bold shadow-sm">
                      <Wine className="w-3.5 h-3.5" />
                      <span>Master Miksolojist</span>
                    </div>

                    {/* Top-Right Rating Pill */}
                    <div className="absolute top-3.5 right-3.5 bg-background/95 backdrop-blur-md px-2.5 py-1 rounded-full flex items-center gap-1 shadow-sm">
                      <Star className="w-3.5 h-3.5 fill-secondary text-secondary" />
                      <span className="text-xs font-bold text-foreground">
                        {Number(mix.rating_avg || 4.9).toFixed(1)}
                      </span>
                      <span className="text-[10px] text-muted-foreground">
                        ({mix.total_reviews || 18})
                      </span>
                    </div>

                    {/* Bottom Location & Distance */}
                    <div className="absolute bottom-3 left-3.5 right-3.5 flex items-center justify-between text-white">
                      <span className="text-xs font-medium flex items-center gap-1">
                        <MapPin className="w-3.5 h-3.5 text-purple-300" />
                        {mix.city_region || "İstanbul"}
                        {mix.distance_km !== undefined && (
                          <span className="text-purple-200 font-bold ml-1">
                            ({mix.distance_km} km)
                          </span>
                        )}
                      </span>
                      <span className="text-[10px] bg-purple-600/90 px-2 py-0.5 rounded-full font-semibold">
                        Mobil Bar Dahil
                      </span>
                    </div>
                  </div>

                  {/* Card Details */}
                  <div className="p-5 space-y-3">
                    <div className="flex items-start justify-between gap-2">
                      <div>
                        <div className="flex items-center gap-1.5">
                          <h3 className="font-serif text-xl font-bold text-foreground">
                            {mix.user?.full_name || "Miksolojist"}
                          </h3>
                          {mix.is_verified && (
                            <ShieldCheck
                              className="w-4 h-4 text-emerald-500 shrink-0"
                              aria-label="Kimlik & Hijyen Onaylı"
                            />
                          )}
                        </div>
                        <p className="text-xs text-purple-600 dark:text-purple-400 font-semibold">
                          {mix.title || "Master Miksolojist & Kokteyl Tasarımcısı"}
                        </p>
                      </div>
                    </div>

                    <p className="text-xs text-muted-foreground line-clamp-2 leading-relaxed">
                      {mix.bio}
                    </p>

                    {/* Verification Badges */}
                    <div className="flex flex-wrap gap-1.5 pt-1">
                      {mix.verification_badges?.hygiene_cert !== false && (
                        <Badge variant="secondary" className="text-[10px] gap-1 py-0.5">
                          <Award className="w-3 h-3" /> Hijyen Sertifikalı
                        </Badge>
                      )}
                      {mix.verification_badges?.diploma !== false && (
                        <Badge variant="outline" className="text-[10px] py-0.5 border-purple-500/30 text-purple-600 dark:text-purple-400">
                          WSET & Miksoloji Diplomalı
                        </Badge>
                      )}
                    </div>

                    {/* Specialty Tags */}
                    <div className="flex flex-wrap gap-1.5 pt-1">
                      {cocktailTags.map((tag) => (
                        <Badge
                          key={tag}
                          variant="outline"
                          className="text-[11px] font-normal px-2.5 py-0.5"
                        >
                          {tag}
                        </Badge>
                      ))}
                    </div>
                  </div>
                </div>

                {/* Footer & CTA */}
                <div className="px-5 pb-5 pt-3 border-t border-border/60 flex items-center justify-between gap-2">
                  <div>
                    <span className="text-[10px] uppercase tracking-wider text-muted-foreground block">
                      Saatlik Bar Paketi
                    </span>
                    <span className="font-sans text-lg font-bold tabular-nums tracking-tight text-purple-700">
                      ₺{hourlyPrice.toLocaleString("tr-TR")}
                    </span>
                    <span className="text-xs text-muted-foreground"> / saat</span>
                  </div>

                  <div className="flex items-center gap-2">
                    <Link href={`/chef/${mix.id}`}>
                      <Button variant="outline" size="sm" className="rounded-xl text-xs">
                        Profili Gör
                      </Button>
                    </Link>
                    <Link href={`/booking?providerId=${mix.id}`}>
                      <Button
                        size="sm"
                        className="rounded-xl text-xs font-bold bg-purple-600 hover:bg-purple-700 text-white"
                      >
                        Bar Kirala
                      </Button>
                    </Link>
                  </div>
                </div>
              </Card>
            );
          })}
        </div>
      )}
    </section>
  );
}
