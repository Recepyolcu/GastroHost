"use client";

import * as React from "react";
import Link from "next/link";
import {
  Star,
  MapPin,
  ShieldCheck,
  Award,
  Search,
  SlidersHorizontal,
  Loader2,
  ChefHat,
} from "lucide-react";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { supabase } from "@/lib/supabase";
import { useAuth } from "@/lib/auth-context";

interface ChefCardData {
  id: string;
  user_id: string;
  provider_type: string;
  title: string;
  bio: string;
  city_region: string;
  service_radius_km: number;
  hourly_rate: number;
  rating_avg: number;
  total_reviews: number;
  is_verified: boolean;
  is_available_now: boolean;
  portfolio_images: string[];
  specialties?: {
    cuisines?: string[];
    dietary?: string[];
  };
  verification_badges?: {
    identity?: boolean;
    criminal_record?: boolean;
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
    ingredients_included: boolean;
    category: string;
  }[];
  distance_km?: number;
}

export function RecommendedChefs() {
  const { userLocation, activeCategory } = useAuth();
  const [chefs, setChefs] = React.useState<ChefCardData[]>([]);
  const [loading, setLoading] = React.useState<boolean>(true);
  const [searchQuery, setSearchQuery] = React.useState<string>("");
  const [maxPrice, setMaxPrice] = React.useState<number>(5000);
  const [onlyIngredientsIncluded, setOnlyIngredientsIncluded] = React.useState<boolean>(false);

  React.useEffect(() => {
    let mounted = true;

    const fetchChefs = async () => {
      setLoading(true);
      try {
        // 1. Query PostGIS RPC for distance calculation
        const { data: nearbyData } = await supabase.rpc("get_nearby_providers", {
          user_lat: userLocation.lat,
          user_lng: userLocation.lng,
          target_type: "chef",
        });

        const distanceMap = new Map<string, number>();
        if (Array.isArray(nearbyData)) {
          nearbyData.forEach((row: { provider_id: string; distance_km: number }) => {
            distanceMap.set(row.provider_id, Number(row.distance_km));
          });
        }

        // 2. Query full provider_profiles with menus and user profiles
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
              ingredients_included,
              category
            )
          `
          )
          .in("provider_type", ["chef", "both"])
          .order("rating_avg", { ascending: false });

        if (!error && data && mounted) {
          const enriched = (data as unknown as ChefCardData[]).map((item) => ({
            ...item,
            distance_km: distanceMap.get(item.id),
          }));
          setChefs(enriched);
        }
      } catch (e) {
        console.error("Error loading chefs:", e);
      } finally {
        if (mounted) setLoading(false);
      }
    };

    fetchChefs();
    return () => {
      mounted = false;
    };
  }, [userLocation.lat, userLocation.lng]);

  if (activeCategory === "bartender") {
    return null;
  }

  const filteredChefs = chefs.filter((chef) => {
    const minMenuPrice =
      chef.menus && chef.menus.length > 0
        ? Math.min(...chef.menus.map((m) => Number(m.price_per_person)))
        : Number(chef.hourly_rate || 1200);

    if (minMenuPrice > maxPrice) return false;

    if (
      onlyIngredientsIncluded &&
      chef.menus &&
      chef.menus.length > 0 &&
      !chef.menus.some((m) => m.ingredients_included)
    ) {
      return false;
    }

    if (activeCategory !== "all" && activeCategory !== "chef") {
      const cuisines = chef.specialties?.cuisines || [];
      const dietary = chef.specialties?.dietary || [];
      const bio = chef.bio || "";
      const title = chef.title || "";
      const catMatch =
        cuisines.some((c) => c.toLowerCase().includes(activeCategory.toLowerCase())) ||
        dietary.some((d) => d.toLowerCase().includes(activeCategory.toLowerCase())) ||
        bio.toLowerCase().includes(activeCategory.toLowerCase()) ||
        title.toLowerCase().includes(activeCategory.toLowerCase());
      if (!catMatch) return false;
    }

    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      const name = chef.user?.full_name?.toLowerCase() || "";
      const title = chef.title?.toLowerCase() || "";
      const bio = chef.bio?.toLowerCase() || "";
      const cuisines = (chef.specialties?.cuisines || []).join(" ").toLowerCase();
      return name.includes(q) || title.includes(q) || bio.includes(q) || cuisines.includes(q);
    }

    return true;
  });

  return (
    <section className="w-full space-y-6">
      {/* Section Header & Live Filters */}
      <div className="flex flex-col lg:flex-row lg:items-end justify-between gap-4">
        <div>
          <h2 className="font-serif text-2xl md:text-3xl font-bold tracking-tight text-foreground">
            Bölgenizdeki Özel Şefler
          </h2>
          <p className="text-sm text-muted-foreground mt-1">
            {userLocation.label} konumuna hizmet veren doğrulanmış şefler ve tadım menüleri
          </p>
        </div>

        {/* Filter Controls */}
        <div className="flex flex-wrap items-center gap-3 bg-card border border-border p-2.5 rounded-2xl shadow-xs">
          <div className="relative w-full sm:w-56">
            <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground" />
            <Input
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Şef veya mutfak ara..."
              className="pl-9 h-9 text-xs"
            />
          </div>

          <div className="flex items-center gap-2 px-2 text-xs">
            <SlidersHorizontal className="w-3.5 h-3.5 text-secondary" />
            <span className="text-muted-foreground">Maks:</span>
            <select
              value={maxPrice}
              onChange={(e) => setMaxPrice(Number(e.target.value))}
              className="bg-muted px-2 py-1 rounded-lg font-semibold text-foreground focus:outline-none"
            >
              <option value={1500}>₺1.500 / kişi</option>
              <option value={2500}>₺2.500 / kişi</option>
              <option value={3500}>₺3.500 / kişi</option>
              <option value={5000}>Tüm Fiyatlar</option>
            </select>
          </div>

          <label className="flex items-center gap-1.5 text-xs font-medium px-2 cursor-pointer">
            <input
              type="checkbox"
              checked={onlyIngredientsIncluded}
              onChange={(e) => setOnlyIngredientsIncluded(e.target.checked)}
              className="accent-secondary rounded"
            />
            <span>Malzeme Dahil</span>
          </label>
        </div>
      </div>

      {/* Chefs Grid */}
      {loading ? (
        <div className="flex items-center justify-center py-16">
          <Loader2 className="w-8 h-8 animate-spin text-secondary" />
        </div>
      ) : filteredChefs.length === 0 ? (
        <div className="text-center py-14 bg-card border border-border rounded-2xl p-6">
          <ChefHat className="w-10 h-10 text-muted-foreground mx-auto mb-2" />
          <h3 className="font-serif text-lg font-bold">Filtreye Uygun Şef Bulunamadı</h3>
          <p className="text-xs text-muted-foreground mt-1">
            Fiyat limitini artırabilir veya kategori filtresini &quot;Tümü&quot; olarak değiştirebilirsiniz.
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredChefs.map((chef) => {
            const minPrice =
              chef.menus && chef.menus.length > 0
                ? Math.min(...chef.menus.map((m) => Number(m.price_per_person)))
                : Number(chef.hourly_rate || 1200);

            const coverImg =
              chef.portfolio_images?.[0] ||
              chef.user?.avatar_url ||
              "https://images.unsplash.com/photo-1577219491135-ce391730fb2c?auto=format&fit=crop&w=800&q=80";

            const tags = [
              ...(chef.specialties?.cuisines || []).slice(0, 2),
              ...(chef.specialties?.dietary || []).slice(0, 1),
            ];

            return (
              <Card
                key={chef.id}
                className="group hover:-translate-y-1 transition-all duration-300 border border-border/60 bg-card overflow-hidden flex flex-col justify-between"
              >
                <div>
                  {/* Cover Image & Badges */}
                  <div className="relative h-56 w-full overflow-hidden">
                    <img
                      src={coverImg}
                      alt={chef.user?.full_name || "Özel Şef"}
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                    />
                    <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-transparent to-transparent" />

                    {/* Rating Pill */}
                    <div className="absolute top-3.5 right-3.5 bg-background/95 backdrop-blur-md px-2.5 py-1 rounded-full flex items-center gap-1 shadow-sm">
                      <Star className="w-3.5 h-3.5 fill-secondary text-secondary" />
                      <span className="text-xs font-bold text-foreground">
                        {Number(chef.rating_avg || 5.0).toFixed(1)}
                      </span>
                      <span className="text-[10px] text-muted-foreground">
                        ({chef.total_reviews || 0})
                      </span>
                    </div>

                    {/* Distance Pill */}
                    <div className="absolute top-3.5 left-3.5 bg-black/65 backdrop-blur-md text-white px-2.5 py-1 rounded-full flex items-center gap-1 text-[11px] font-medium">
                      <MapPin className="w-3 h-3 text-secondary" />
                      <span>
                        {chef.distance_km !== undefined
                          ? `${chef.distance_km} km uzaklıkta`
                          : chef.city_region || "İstanbul"}
                      </span>
                    </div>

                    {/* Verification & Trust Badges */}
                    <div className="absolute bottom-3 left-3.5 right-3.5 flex flex-wrap items-center gap-1.5">
                      {chef.is_verified && (
                        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-emerald-500/90 text-white text-[10px] font-bold">
                          <ShieldCheck className="w-3 h-3" /> Onaylı Profil
                        </span>
                      )}
                      {chef.verification_badges?.diploma && (
                        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-amber-500/90 text-slate-950 text-[10px] font-bold">
                          <Award className="w-3 h-3" /> Diplomalı Şef
                        </span>
                      )}
                      {chef.verification_badges?.hygiene_cert && (
                        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-teal-500/90 text-slate-950 text-[10px] font-bold">
                          <Award className="w-3 h-3" /> Hijyen Sertifikalı
                        </span>
                      )}
                    </div>
                  </div>

                  {/* Card Content */}
                  <div className="p-5 space-y-3">
                    <div className="flex justify-between items-start gap-2">
                      <div>
                        <h3 className="font-serif text-xl font-bold text-foreground">
                          {chef.user?.full_name || "Şef"}
                        </h3>
                        <p className="text-xs font-medium text-secondary line-clamp-1">
                          {chef.title || "Özel Fine Dining Şefi"}
                        </p>
                      </div>
                      <div className="text-right shrink-0">
                        <div className="font-sans text-lg font-bold tabular-nums tracking-tight text-foreground">
                          ₺{minPrice.toLocaleString("tr-TR")}
                        </div>
                        <div className="text-[10px] text-muted-foreground">/ kişi başı</div>
                      </div>
                    </div>

                    <p className="text-xs text-muted-foreground line-clamp-2 leading-relaxed">
                      {chef.bio ||
                        "Evinizde mevsimsel ve taze ürünlerle hazırlanan özel tadım menüsü deneyimi."}
                    </p>

                    {/* Tags */}
                    {tags.length > 0 && (
                      <div className="flex flex-wrap gap-1.5 pt-1">
                        {tags.map((tag) => (
                          <Badge key={tag} variant="outline" className="text-[11px] font-normal">
                            {tag}
                          </Badge>
                        ))}
                      </div>
                    )}
                  </div>
                </div>

                {/* Action Footer */}
                <div className="px-5 pb-5 pt-2 flex items-center gap-2">
                  <Link href={`/chef/${chef.id}`} className="flex-1">
                    <Button variant="outline" className="w-full font-semibold text-xs rounded-xl">
                      Menüleri & Profili Gör
                    </Button>
                  </Link>
                  <Link href={`/booking?providerId=${chef.id}`}>
                    <Button className="font-bold text-xs rounded-xl px-4">Rezerve Et</Button>
                  </Link>
                </div>
              </Card>
            );
          })}
        </div>
      )}
    </section>
  );
}
