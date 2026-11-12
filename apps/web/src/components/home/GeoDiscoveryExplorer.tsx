"use client";

import * as React from "react";
import Link from "next/link";
import {
  MapPin,
  Navigation,
  Search,
  SlidersHorizontal,
  Calendar,
  Clock,
  Sparkles,
  ShieldCheck,
  ShoppingBag,
  Utensils,
  Wine,
  Star,
  Map as MapIcon,
  LayoutGrid,
  Columns,
  RotateCcw,
  CheckCircle2,
  Compass,
  Loader2,
  ArrowRight,
} from "lucide-react";
import { supabase } from "@/lib/supabase";
import { useAuth, ISTANBUL_DISTRICTS } from "@/lib/auth-context";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  InteractiveDiscoveryMap,
  GeoProviderItem,
} from "@/components/home/InteractiveDiscoveryMap";

type ViewMode = "split" | "list" | "map";
type ServiceFilter = "all" | "chef" | "bartender" | "combo";
type SortOption = "distance" | "rating" | "price_asc";

const CUISINE_FILTERS = [
  { id: "all", label: "Tüm Mutfaklar" },
  { id: "İtalyan", label: "🍝 İtalyan" },
  { id: "Japon", label: "🍣 Japon & Omakase" },
  { id: "Ege", label: "🫒 Ege & Akdeniz" },
  { id: "Barbekü", label: "🥩 Barbekü & Et" },
  { id: "Modern Anadolu", label: "🏺 Modern Anadolu" },
  { id: "Vegan", label: "🥗 Glutensiz / Vegan" },
  { id: "Kokteyl", label: "🍸 Kokteyl & Miksoloji" },
];

const RADIUS_OPTIONS = [5, 10, 15, 25, 35, 50];

const PRICE_LIMIT_OPTIONS = [
  { value: 0, label: "Tüm Bütçeler" },
  { value: 1000, label: "Maks. ₺1.000 / Kişi" },
  { value: 1500, label: "Maks. ₺1.500 / Kişi" },
  { value: 2000, label: "Maks. ₺2.000 / Kişi" },
  { value: 2500, label: "Maks. ₺2.500 / Kişi" },
  { value: 3500, label: "Maks. ₺3.500 / Kişi" },
];

const CATEGORY_TO_CUISINE_MAP: Record<string, string> = {
  all: "all",
  italian: "İtalyan",
  "İtalyan": "İtalyan",
  japanese: "Japon",
  "Japon": "Japon",
  mediterranean: "Ege",
  "Akdeniz": "Ege",
  bbq: "Barbekü",
  anatolian: "Modern Anadolu",
  "Anadolu": "Modern Anadolu",
  vegan: "Vegan",
  "Glutensiz": "Vegan",
  mixology: "Kokteyl",
};

const FALLBACK_AVATARS = [
  "https://images.unsplash.com/photo-1577219491135-ce391730fb2c?auto=format&fit=crop&w=800&q=80",
  "https://images.unsplash.com/photo-1583394838336-acd977736f90?auto=format&fit=crop&w=800&q=80",
  "https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?auto=format&fit=crop&w=800&q=80",
];

function getSpecialtyTags(provider: GeoProviderItem): string[] {
  const s = provider.specialties;
  if (!s) return [];
  return [
    ...(s.cuisines || []),
    ...(s.dietary || []),
    ...(s.cocktails || []),
  ];
}

function getBadgeLabels(provider: GeoProviderItem): string[] {
  const b = provider.verification_badges;
  if (!b) return [];
  const list: string[] = [];
  if (b.hygiene_cert) list.push("Hijyen Sertifikalı");
  if (b.diploma) list.push("Diplomalı Şef");
  if (b.identity) list.push("Kimlik Onaylı");
  return list;
}

export function GeoDiscoveryExplorer() {
  const { userLocation, setUserLocation, activeCategory, setActiveCategory } = useAuth();

  // View Mode: Split (List + Map), List only, or Full Map
  const [viewMode, setViewMode] = React.useState<ViewMode>("split");

  // PostGIS & PRD 3.2 Filter States
  const [maxDistanceKm, setMaxDistanceKm] = React.useState<number>(25);
  const [serviceType, setServiceType] = React.useState<ServiceFilter>("all");
  const [cuisineFilter, setCuisineFilter] = React.useState<string>("all");
  const [maxPricePerPerson, setMaxPricePerPerson] = React.useState<number>(0);
  const [onlyIngredientsIncluded, setOnlyIngredientsIncluded] = React.useState<boolean>(false);
  const [onlyHygieneCertified, setOnlyHygieneCertified] = React.useState<boolean>(false);
  const [onlyDiplomaCertified, setOnlyDiplomaCertified] = React.useState<boolean>(false);
  const [onlyAvailableOnDate, setOnlyAvailableOnDate] = React.useState<boolean>(false);
  const [onlyWithinProviderRadius, setOnlyWithinProviderRadius] = React.useState<boolean>(false);
  const [eventDate, setEventDate] = React.useState<string>(
    new Date(Date.now() + 86400000 * 3).toISOString().split("T")[0]
  );
  const [eventTime, setEventTime] = React.useState<string>("19:30");
  const [searchQuery, setSearchQuery] = React.useState<string>("");
  const [sortBy, setSortBy] = React.useState<SortOption>("distance");

  // Address Geocoding Search State
  const [addressInput, setAddressInput] = React.useState<string>("");
  const [searchingAddress, setSearchingAddress] = React.useState<boolean>(false);
  const [locatingGps, setLocatingGps] = React.useState<boolean>(false);

  // Data & Map Selection State
  const [providers, setProviders] = React.useState<GeoProviderItem[]>([]);
  const [loading, setLoading] = React.useState<boolean>(true);
  const [selectedProviderId, setSelectedProviderId] = React.useState<string | null>(null);
  const [showAdvancedDrawer, setShowAdvancedDrawer] = React.useState<boolean>(false);

  // Sync top CategoryScroll bar with our cuisine/service filters
  React.useEffect(() => {
    if (activeCategory === "mixology" || activeCategory === "bartender") {
      setServiceType("bartender");
      setCuisineFilter("all");
    } else if (activeCategory === "chef") {
      setServiceType("chef");
      setCuisineFilter("all");
    } else if (activeCategory === "all") {
      setServiceType("all");
      setCuisineFilter("all");
    } else {
      const mapped = CATEGORY_TO_CUISINE_MAP[activeCategory] || "all";
      setCuisineFilter(mapped);
      if (serviceType === "bartender") {
        setServiceType("all");
      }
    }
  }, [activeCategory]);

  const fetchGeoProviders = React.useCallback(async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase.rpc("discover_providers_postgis", {
        p_user_lat: userLocation.lat,
        p_user_lng: userLocation.lng,
        p_max_distance_km: maxDistanceKm,
        p_service_type: serviceType,
        p_cuisine: cuisineFilter === "all" ? null : cuisineFilter,
        p_max_price: maxPricePerPerson > 0 ? maxPricePerPerson : null,
        p_ingredients_included: onlyIngredientsIncluded,
        p_event_date: eventDate || null,
        p_event_time: eventTime || null,
      });

      if (error) {
        console.error("PostGIS RPC error:", error);
        setProviders([]);
      } else {
        setProviders((data as GeoProviderItem[]) || []);
      }
    } catch (err) {
      console.error("Failed to fetch PostGIS providers:", err);
    } finally {
      setLoading(false);
    }
  }, [
    userLocation.lat,
    userLocation.lng,
    maxDistanceKm,
    serviceType,
    cuisineFilter,
    maxPricePerPerson,
    onlyIngredientsIncluded,
    eventDate,
    eventTime,
  ]);

  React.useEffect(() => {
    fetchGeoProviders();
  }, [fetchGeoProviders]);

  // Client-side refinements (text search, badge filters, date availability toggle, sort)
  const filteredProviders = React.useMemo(() => {
    return providers
      .filter((p) => {
        if (onlyAvailableOnDate && !p.available_on_date) return false;
        if (onlyWithinProviderRadius && !p.within_provider_radius) return false;
        if (onlyHygieneCertified && !p.verification_badges?.hygiene_cert) {
          return false;
        }
        if (onlyDiplomaCertified && !p.verification_badges?.diploma) {
          return false;
        }
        if (searchQuery.trim() !== "") {
          const q = searchQuery.toLowerCase();
          const nameMatch = (p.full_name || "").toLowerCase().includes(q);
          const titleMatch = (p.title || "").toLowerCase().includes(q);
          const cityMatch = (p.city_region || "").toLowerCase().includes(q);
          const tags = getSpecialtyTags(p);
          const cuisineMatch = tags.some((c: string) =>
            c.toLowerCase().includes(q)
          );
          if (!nameMatch && !titleMatch && !cityMatch && !cuisineMatch) {
            return false;
          }
        }
        return true;
      })
      .sort((a, b) => {
        if (sortBy === "distance") return a.distance_km - b.distance_km;
        if (sortBy === "rating") return (b.rating_avg || 0) - (a.rating_avg || 0);
        if (sortBy === "price_asc") {
          const priceA = a.min_menu_price || a.hourly_rate || 0;
          const priceB = b.min_menu_price || b.hourly_rate || 0;
          return priceA - priceB;
        }
        return 0;
      });
  }, [
    providers,
    onlyAvailableOnDate,
    onlyWithinProviderRadius,
    onlyHygieneCertified,
    onlyDiplomaCertified,
    searchQuery,
    sortBy,
  ]);

  // Featured Mixologist for "Combo (Chef + Bartender)" mode
  const featuredMixologist = React.useMemo(() => {
    return providers.find(
      (p) => p.provider_type === "bartender" || p.provider_type === "both"
    );
  }, [providers]);

  const handleGeocodeAddress = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!addressInput.trim()) return;
    setSearchingAddress(true);
    try {
      const q = encodeURIComponent(`${addressInput.trim()}, İstanbul, Türkiye`);
      const res = await fetch(
        `https://nominatim.openstreetmap.org/search?format=json&q=${q}&limit=1`,
        { headers: { "Accept-Language": "tr" } }
      );
      if (res.ok) {
        const results = await res.json();
        if (results && results.length > 0) {
          const hit = results[0];
          const lat = parseFloat(hit.lat);
          const lng = parseFloat(hit.lon);
          const shortLabel =
            hit.display_name?.split(",").slice(0, 2).join(", ") ||
            addressInput.trim();
          setUserLocation({ label: shortLabel, lat, lng });
          setAddressInput("");
        }
      }
    } catch (err) {
      console.error("Address search error:", err);
    } finally {
      setSearchingAddress(false);
    }
  };

  const handleDetectGps = () => {
    if (typeof window === "undefined" || !("geolocation" in navigator)) return;
    setLocatingGps(true);
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setUserLocation({
          label: `GPS Konumum (${pos.coords.latitude.toFixed(3)}, ${pos.coords.longitude.toFixed(3)})`,
          lat: pos.coords.latitude,
          lng: pos.coords.longitude,
        });
        setLocatingGps(false);
      },
      () => {
        // Fallback to Kadıköy Moda if permission denied in browser
        setUserLocation({
          label: "Moda / Kadıköy, İstanbul",
          lat: 40.9805,
          lng: 29.0262,
        });
        setLocatingGps(false);
      },
      { timeout: 6000 }
    );
  };

  const resetAllFilters = () => {
    setMaxDistanceKm(25);
    setServiceType("all");
    setCuisineFilter("all");
    setActiveCategory("all");
    setMaxPricePerPerson(0);
    setOnlyIngredientsIncluded(false);
    setOnlyHygieneCertified(false);
    setOnlyDiplomaCertified(false);
    setOnlyAvailableOnDate(false);
    setOnlyWithinProviderRadius(false);
    setSearchQuery("");
    setSortBy("distance");
  };

  const activeFilterCount =
    (serviceType !== "all" ? 1 : 0) +
    (cuisineFilter !== "all" ? 1 : 0) +
    (maxPricePerPerson > 0 ? 1 : 0) +
    (onlyIngredientsIncluded ? 1 : 0) +
    (onlyHygieneCertified ? 1 : 0) +
    (onlyDiplomaCertified ? 1 : 0) +
    (onlyAvailableOnDate ? 1 : 0) +
    (onlyWithinProviderRadius ? 1 : 0) +
    (searchQuery.trim() !== "" ? 1 : 0);

  return (
    <section
      id="geo-discovery"
      className="flex flex-col gap-6 bg-white rounded-3xl border border-stone-200/90 p-6 md:p-8 shadow-sm"
    >
      {/* Top Section Header & View Switcher */}
      <div className="flex flex-col xl:flex-row xl:items-center justify-between gap-4 pb-5 border-b border-stone-100">
        <div className="space-y-1">
          <div className="flex flex-wrap items-center gap-2">
            <Badge className="bg-amber-800/10 text-amber-900 border-amber-800/20 font-bold text-[11px] uppercase tracking-wider">
              <Compass className="w-3.5 h-3.5 mr-1 text-amber-800" />
              Konum & Harita Keşfi
            </Badge>
            <Badge
              variant="outline"
              className="bg-emerald-50 text-emerald-800 border-emerald-200 text-[11px] font-semibold"
            >
              {maxDistanceKm} km Çevrede Arama
            </Badge>
          </div>
          <h2 className="font-serif text-2xl md:text-3xl font-bold tracking-tight text-stone-900">
            Konum Bazlı Şef & Miksolojist Keşfi
          </h2>
          <p className="text-xs md:text-sm text-stone-500">
            Semtinizi seçin veya haritadan konum belirleyin; size en yakın onaylı şef ve miksolojistleri keşfedin.
          </p>
        </div>

        {/* View Mode Switcher + Filter Drawer Button on a Single Clean Line */}
        <div className="flex flex-wrap sm:flex-nowrap items-center gap-2.5 shrink-0">
          <div className="inline-flex rounded-xl bg-stone-100 p-1 border border-stone-200/80">
            <button
              type="button"
              onClick={() => setViewMode("split")}
              className={`flex items-center gap-1.5 px-3.5 py-2 rounded-lg text-xs font-semibold transition-all cursor-pointer whitespace-nowrap ${
                viewMode === "split"
                  ? "bg-white text-stone-900 shadow-xs"
                  : "text-stone-600 hover:text-stone-900"
              }`}
            >
              <Columns className="w-3.5 h-3.5 text-amber-800" />
              Liste + Harita
            </button>
            <button
              type="button"
              onClick={() => setViewMode("list")}
              className={`flex items-center gap-1.5 px-3.5 py-2 rounded-lg text-xs font-semibold transition-all cursor-pointer whitespace-nowrap ${
                viewMode === "list"
                  ? "bg-white text-stone-900 shadow-xs"
                  : "text-stone-600 hover:text-stone-900"
              }`}
            >
              <LayoutGrid className="w-3.5 h-3.5 text-amber-800" />
              Sadece Liste
            </button>
            <button
              type="button"
              onClick={() => setViewMode("map")}
              className={`flex items-center gap-1.5 px-3.5 py-2 rounded-lg text-xs font-semibold transition-all cursor-pointer whitespace-nowrap ${
                viewMode === "map"
                  ? "bg-white text-stone-900 shadow-xs"
                  : "text-stone-600 hover:text-stone-900"
              }`}
            >
              <MapIcon className="w-3.5 h-3.5 text-amber-800" />
              Tam Harita
            </button>
          </div>

          <Button
            type="button"
            variant="outline"
            size="sm"
            onClick={() => setShowAdvancedDrawer((prev) => !prev)}
            className={`h-9 px-3.5 rounded-xl text-xs font-semibold gap-1.5 cursor-pointer whitespace-nowrap ${
              showAdvancedDrawer
                ? "bg-amber-50 border-amber-800/40 text-amber-950"
                : "border-stone-200 text-stone-700"
            }`}
          >
            <SlidersHorizontal className="w-3.5 h-3.5 text-amber-800" />
            {showAdvancedDrawer ? "Filtreleri Gizle" : "Detaylı Filtreler"}
            {activeFilterCount > 0 && (
              <span className="ml-0.5 px-1.5 py-0.5 rounded-full bg-amber-800 text-white text-[10px] font-bold leading-none">
                {activeFilterCount}
              </span>
            )}
          </Button>
        </div>
      </div>

      {/* Main Unified Filter Bar (Spacious & Uncluttered) */}
      <div className="flex flex-col gap-4 bg-stone-50/70 p-4 md:p-5 rounded-2xl border border-stone-200/80">
        {/* Row 1: Service Type Tabs + Search + Radius + Sort */}
        <div className="flex flex-col xl:flex-row xl:items-center justify-between gap-3.5">
          {/* Left: Service Type Pills (Single Line) */}
          <div className="flex items-center gap-2 overflow-x-auto no-scrollbar pb-0.5">
            <button
              type="button"
              onClick={() => setServiceType("all")}
              className={`px-3.5 py-2 rounded-xl text-xs font-bold transition-all border shrink-0 cursor-pointer ${
                serviceType === "all"
                  ? "bg-stone-900 text-white border-stone-900 shadow-xs"
                  : "bg-white text-stone-700 border-stone-200 hover:bg-stone-100"
              }`}
            >
              Tümü ({providers.length})
            </button>
            <button
              type="button"
              onClick={() => setServiceType("chef")}
              className={`flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-bold transition-all border shrink-0 cursor-pointer ${
                serviceType === "chef"
                  ? "bg-amber-800 text-white border-amber-800 shadow-xs"
                  : "bg-white text-stone-700 border-stone-200 hover:bg-stone-100"
              }`}
            >
              <Utensils className="w-3.5 h-3.5" />
              Özel Şef
            </button>
            <button
              type="button"
              onClick={() => setServiceType("bartender")}
              className={`flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-bold transition-all border shrink-0 cursor-pointer ${
                serviceType === "bartender"
                  ? "bg-purple-900 text-white border-purple-900 shadow-xs"
                  : "bg-white text-stone-700 border-stone-200 hover:bg-stone-100"
              }`}
            >
              <Wine className="w-3.5 h-3.5" />
              Miksolojist
            </button>
            <button
              type="button"
              onClick={() => setServiceType("combo")}
              className={`flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-bold transition-all border shrink-0 cursor-pointer ${
                serviceType === "combo"
                  ? "bg-gradient-to-r from-amber-800 to-purple-900 text-white border-amber-900 shadow-xs"
                  : "bg-white text-stone-700 border-stone-200 hover:bg-stone-100"
              }`}
            >
              <Sparkles className="w-3.5 h-3.5" />
              Şef + Bar Paketi
            </button>
          </div>

          {/* Right: Search Input + Distance Select + Sort Select */}
          <div className="flex flex-wrap sm:flex-nowrap items-center gap-2.5">
            <div className="relative flex-1 sm:w-60">
              <Search className="w-3.5 h-3.5 text-stone-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
              <Input
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Şef, mutfak veya menü ara..."
                className="pl-9 h-9 bg-white text-xs rounded-xl border-stone-200"
              />
            </div>

            <select
              value={maxDistanceKm}
              onChange={(e) => setMaxDistanceKm(Number(e.target.value))}
              className="h-9 px-3 rounded-xl bg-white border border-stone-200 text-xs font-semibold text-stone-800 cursor-pointer"
              title="Arama Yarıçapı"
            >
              {RADIUS_OPTIONS.map((km) => (
                <option key={km} value={km}>
                  Mesafe: {km} km
                </option>
              ))}
            </select>

            <select
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value as SortOption)}
              className="h-9 px-3 rounded-xl bg-white border border-stone-200 text-xs font-semibold text-stone-800 cursor-pointer"
            >
              <option value="distance">Sırala: En Yakın</option>
              <option value="rating">Sırala: En Yüksek Puan</option>
              <option value="price_asc">Sırala: Fiyat (Artan)</option>
            </select>
          </div>
        </div>

        {/* Row 2: Quick District Selector + GPS Button */}
        <div className="flex flex-wrap items-center justify-between gap-3 pt-3 border-t border-stone-200/60">
          <div className="flex items-center gap-1.5 overflow-x-auto no-scrollbar py-0.5">
            <span className="inline-flex items-center gap-1 text-xs font-bold text-stone-700 shrink-0 mr-1">
              <MapPin className="w-3.5 h-3.5 text-amber-800" />
              Semt:
            </span>
            {ISTANBUL_DISTRICTS.map((dist) => {
              const isSelected = userLocation.label === dist.label;
              return (
                <button
                  key={dist.label}
                  type="button"
                  onClick={() => setUserLocation(dist)}
                  className={`px-3 py-1.5 rounded-full text-xs font-semibold shrink-0 transition-all border cursor-pointer ${
                    isSelected
                      ? "bg-amber-800 text-white border-amber-800 shadow-2xs"
                      : "bg-white text-stone-700 border-stone-200 hover:border-amber-800/40"
                  }`}
                >
                  {dist.label.replace(", İstanbul", "")}
                </button>
              );
            })}
            <button
              type="button"
              onClick={handleDetectGps}
              disabled={locatingGps}
              className="inline-flex items-center gap-1 px-3 py-1.5 rounded-full text-xs font-bold bg-white text-amber-900 border border-amber-800/30 hover:bg-amber-50 shrink-0 transition cursor-pointer ml-1"
            >
              {locatingGps ? (
                <Loader2 className="w-3 h-3 animate-spin" />
              ) : (
                <Navigation className="w-3 h-3 text-amber-800" />
              )}
              GPS Konumum
            </button>
          </div>

          {/* Cuisine Filter Pills */}
          <div className="flex items-center gap-1.5 overflow-x-auto no-scrollbar py-0.5">
            {CUISINE_FILTERS.map((c) => {
              const active = cuisineFilter === c.id;
              return (
                <button
                  key={c.id}
                  type="button"
                  onClick={() => setCuisineFilter(c.id)}
                  className={`px-3 py-1.5 rounded-xl text-xs font-semibold shrink-0 transition-all border cursor-pointer ${
                    active
                      ? "bg-stone-900 text-white border-stone-900"
                      : "bg-white text-stone-600 border-stone-200 hover:border-stone-300"
                  }`}
                >
                  {c.label}
                </button>
              );
            })}
          </div>
        </div>

        {/* Combo Package Highlight Banner when "combo" tab is selected */}
        {serviceType === "combo" && (
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 p-4 rounded-2xl bg-gradient-to-r from-amber-900 via-stone-900 to-purple-950 text-white">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-white/10 flex items-center justify-center shrink-0">
                <Sparkles className="w-5 h-5 text-amber-300" />
              </div>
              <div>
                <div className="text-xs font-extrabold uppercase tracking-wider text-amber-300">
                  Kombine Paket (Özel Şef + Miksolojist)
                </div>
                <p className="text-xs text-stone-200 mt-0.5">
                  Aşağıdan ana yemek şefinizi seçtiğinizde, rezervasyon sihirbazında{" "}
                  <span className="font-bold text-white">
                    {featuredMixologist?.full_name || "Uzman Miksolojist"}
                  </span>{" "}
                  kokteyl eşleşmesi otomatik olarak paketinize eklenir.
                </p>
              </div>
            </div>
            <Badge className="bg-amber-400 text-stone-950 font-extrabold text-[11px] shrink-0">
              Tek Escrow Ödeme • %10 Komisyon
            </Badge>
          </div>
        )}
      </div>

      {/* Collapsible Advanced Filters Drawer (Spacious 3-Column Layout) */}
      {showAdvancedDrawer && (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-5 p-5 rounded-2xl bg-stone-50/90 border border-stone-200">
          {/* Col 1: Date & Time Availability */}
          <div className="space-y-2">
            <label className="text-[11px] font-bold uppercase tracking-wider text-stone-500 block">
              Etkinlik Tarihi & Saat Müsaitliği
            </label>
            <div className="flex items-center gap-2 bg-white px-3 py-2 rounded-xl border border-stone-200">
              <Calendar className="w-3.5 h-3.5 text-amber-800 shrink-0" />
              <input
                type="date"
                value={eventDate}
                onChange={(e) => setEventDate(e.target.value)}
                className="text-xs font-semibold text-stone-800 bg-transparent focus:outline-none"
              />
              <div className="h-4 w-px bg-stone-200" />
              <Clock className="w-3.5 h-3.5 text-amber-800 shrink-0" />
              <select
                value={eventTime}
                onChange={(e) => setEventTime(e.target.value)}
                className="text-xs font-semibold text-stone-800 bg-transparent focus:outline-none"
              >
                <option value="18:00">18:00</option>
                <option value="19:00">19:00</option>
                <option value="19:30">19:30</option>
                <option value="20:00">20:00</option>
                <option value="21:00">21:00</option>
              </select>
              <button
                type="button"
                onClick={() => setOnlyAvailableOnDate((prev) => !prev)}
                className={`ml-auto px-2.5 py-1 rounded-lg text-[11px] font-bold transition-all cursor-pointer whitespace-nowrap ${
                  onlyAvailableOnDate
                    ? "bg-emerald-700 text-white"
                    : "bg-stone-100 text-stone-600 hover:bg-stone-200"
                }`}
              >
                {onlyAvailableOnDate ? "✓ Müsaitler" : "Tümü"}
              </button>
            </div>
          </div>

          {/* Col 2: Budget & Custom Address Search */}
          <div className="space-y-2">
            <label className="text-[11px] font-bold uppercase tracking-wider text-stone-500 block">
              Kişi Başı Bütçe & Özel Adres Arama
            </label>
            <div className="flex items-center gap-2">
              <select
                value={maxPricePerPerson}
                onChange={(e) => setMaxPricePerPerson(Number(e.target.value))}
                className="h-10 px-3 rounded-xl bg-white border border-stone-200 text-xs font-semibold text-stone-800 shrink-0"
              >
                {PRICE_LIMIT_OPTIONS.map((opt) => (
                  <option key={opt.value} value={opt.value}>
                    {opt.label}
                  </option>
                ))}
              </select>

              <form onSubmit={handleGeocodeAddress} className="flex flex-1 items-center gap-1.5">
                <Input
                  value={addressInput}
                  onChange={(e) => setAddressInput(e.target.value)}
                  placeholder="Cadde veya mahalle ara..."
                  className="h-10 bg-white text-xs rounded-xl border-stone-200"
                />
                <Button
                  type="submit"
                  size="sm"
                  disabled={searchingAddress || !addressInput.trim()}
                  className="h-10 px-3 rounded-xl bg-stone-900 hover:bg-stone-800 text-white text-xs font-semibold shrink-0 cursor-pointer"
                >
                  {searchingAddress ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : "Bul"}
                </Button>
              </form>
            </div>
          </div>

          {/* Col 3: Certificates & Service Feature Toggles */}
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <label className="text-[11px] font-bold uppercase tracking-wider text-stone-500">
                Sertifika & Hizmet Kriterleri
              </label>
              {activeFilterCount > 0 && (
                <button
                  type="button"
                  onClick={resetAllFilters}
                  className="flex items-center gap-1 text-[11px] font-bold text-rose-700 hover:underline cursor-pointer"
                >
                  <RotateCcw className="w-3 h-3" />
                  Sıfırla
                </button>
              )}
            </div>
            <div className="grid grid-cols-2 gap-2">
              <button
                type="button"
                onClick={() => setOnlyIngredientsIncluded((prev) => !prev)}
                className={`flex items-center justify-center gap-1.5 px-3 py-2 rounded-xl text-xs font-semibold border transition-all cursor-pointer ${
                  onlyIngredientsIncluded
                    ? "bg-emerald-50 text-emerald-900 border-emerald-600"
                    : "bg-white text-stone-600 border-stone-200"
                }`}
              >
                <ShoppingBag className="w-3.5 h-3.5 text-emerald-700 shrink-0" />
                Malzeme Dahil
              </button>

              <button
                type="button"
                onClick={() => setOnlyHygieneCertified((prev) => !prev)}
                className={`flex items-center justify-center gap-1.5 px-3 py-2 rounded-xl text-xs font-semibold border transition-all cursor-pointer ${
                  onlyHygieneCertified
                    ? "bg-blue-50 text-blue-900 border-blue-600"
                    : "bg-white text-stone-600 border-stone-200"
                }`}
              >
                <ShieldCheck className="w-3.5 h-3.5 text-blue-700 shrink-0" />
                Hijyen Onaylı
              </button>

              <button
                type="button"
                onClick={() => setOnlyDiplomaCertified((prev) => !prev)}
                className={`flex items-center justify-center gap-1.5 px-3 py-2 rounded-xl text-xs font-semibold border transition-all cursor-pointer ${
                  onlyDiplomaCertified
                    ? "bg-amber-50 text-amber-900 border-amber-600"
                    : "bg-white text-stone-600 border-stone-200"
                }`}
              >
                🎓 Diplomalı
              </button>

              <button
                type="button"
                onClick={() => setOnlyWithinProviderRadius((prev) => !prev)}
                className={`flex items-center justify-center gap-1.5 px-3 py-2 rounded-xl text-xs font-semibold border transition-all cursor-pointer ${
                  onlyWithinProviderRadius
                    ? "bg-stone-900 text-white border-stone-900"
                    : "bg-white text-stone-600 border-stone-200"
                }`}
              >
                🎯 Kapsama İçi
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Results Summary Bar */}
      <div className="flex flex-wrap items-center justify-between gap-2 text-xs text-stone-600 px-1">
        <div className="flex items-center gap-2">
          <span className="font-bold text-stone-900">
            {loading ? "Konuma göre aranıyor..." : `${filteredProviders.length} Profesyonel Bulundu`}
          </span>
          <span>•</span>
          <span>
            Merkez: <strong className="text-stone-800">{userLocation.label}</strong> ({maxDistanceKm} km yarıçap)
          </span>
        </div>
        <div className="flex items-center gap-3 text-[11px]">
          <span className="inline-flex items-center gap-1 text-emerald-700 font-semibold">
            <span className="w-2 h-2 rounded-full bg-emerald-500" />
            Yeşil Rozet: Şefin standart hizmet alanı içindesiniz
          </span>
        </div>
      </div>

      {/* Main Content Area: Split / List / Map */}
      {loading ? (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 py-4">
          {[1, 2, 3].map((n) => (
            <div
              key={n}
              className="h-96 rounded-2xl bg-stone-100 animate-pulse border border-stone-200/60"
            />
          ))}
        </div>
      ) : filteredProviders.length === 0 ? (
        <div className="flex flex-col items-center justify-center text-center py-14 px-4 rounded-2xl bg-stone-50 border border-dashed border-stone-200">
          <MapPin className="w-10 h-10 text-amber-800 mb-3 opacity-80" />
          <h3 className="font-serif text-lg font-bold text-stone-900">
            Bu Konum ve Filtrelerde Şef/Barmen Bulunamadı
          </h3>
          <p className="text-xs text-stone-500 max-w-md mt-1 mb-4">
            Arama yarıçapını ({maxDistanceKm} km) artırabilir veya bütçe / mutfak filtrelerini sıfırlayarak İstanbul genelindeki tüm onaylı profesyonelleri görebilirsiniz.
          </p>
          <div className="flex items-center gap-2">
            <Button
              size="sm"
              onClick={() => setMaxDistanceKm(50)}
              className="rounded-xl bg-amber-800 hover:bg-amber-900 text-white text-xs font-bold"
            >
              Yarıçapı 50 km Yap
            </Button>
            <Button
              size="sm"
              variant="outline"
              onClick={resetAllFilters}
              className="rounded-xl text-xs font-semibold"
            >
              Tüm Filtreleri Temizle
            </Button>
          </div>
        </div>
      ) : viewMode === "map" ? (
        /* Full-Screen Interactive Map Mode */
        <div className="flex flex-col gap-4">
          <InteractiveDiscoveryMap
            userLat={userLocation.lat}
            userLng={userLocation.lng}
            userLabel={userLocation.label}
            searchRadiusKm={maxDistanceKm}
            providers={filteredProviders}
            selectedProviderId={selectedProviderId}
            onSelectProvider={setSelectedProviderId}
            onPickUserLocation={(lat, lng, label) =>
              setUserLocation({ lat, lng, label })
            }
            eventDate={eventDate}
            isComboMode={serviceType === "combo"}
          />
          {/* Horizontal Quick Cards under Map */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {filteredProviders.map((prov, idx) => (
              <ProviderDiscoveryCard
                key={prov.provider_id}
                provider={prov}
                index={idx}
                isSelected={selectedProviderId === prov.provider_id}
                onSelect={() => setSelectedProviderId(prov.provider_id)}
                isComboMode={serviceType === "combo"}
                eventDate={eventDate}
                featuredMixologistName={featuredMixologist?.full_name}
              />
            ))}
          </div>
        </div>
      ) : viewMode === "list" ? (
        /* 3-Column Pure List View */
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredProviders.map((prov, idx) => (
            <ProviderDiscoveryCard
              key={prov.provider_id}
              provider={prov}
              index={idx}
              isSelected={selectedProviderId === prov.provider_id}
              onSelect={() => setSelectedProviderId(prov.provider_id)}
              isComboMode={serviceType === "combo"}
              eventDate={eventDate}
              featuredMixologistName={featuredMixologist?.full_name}
            />
          ))}
        </div>
      ) : (
        /* Split View: Left 2-Column Cards + Right Sticky PostGIS Interactive Map */
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
          <div className="lg:col-span-7 grid grid-cols-1 sm:grid-cols-2 gap-5">
            {filteredProviders.map((prov, idx) => (
              <ProviderDiscoveryCard
                key={prov.provider_id}
                provider={prov}
                index={idx}
                isSelected={selectedProviderId === prov.provider_id}
                onSelect={() => setSelectedProviderId(prov.provider_id)}
                isComboMode={serviceType === "combo"}
                eventDate={eventDate}
                featuredMixologistName={featuredMixologist?.full_name}
              />
            ))}
          </div>

          <div className="lg:col-span-5 lg:sticky lg:top-28">
            <InteractiveDiscoveryMap
              userLat={userLocation.lat}
              userLng={userLocation.lng}
              userLabel={userLocation.label}
              searchRadiusKm={maxDistanceKm}
              providers={filteredProviders}
              selectedProviderId={selectedProviderId}
              onSelectProvider={setSelectedProviderId}
              onPickUserLocation={(lat, lng, label) =>
                setUserLocation({ lat, lng, label })
              }
              eventDate={eventDate}
              isComboMode={serviceType === "combo"}
            />
          </div>
        </div>
      )}
    </section>
  );
}

interface ProviderDiscoveryCardProps {
  provider: GeoProviderItem;
  index: number;
  isSelected: boolean;
  onSelect: () => void;
  isComboMode: boolean;
  eventDate: string;
  featuredMixologistName?: string;
}

function ProviderDiscoveryCard({
  provider,
  index,
  isSelected,
  onSelect,
  isComboMode,
  eventDate,
  featuredMixologistName,
}: ProviderDiscoveryCardProps) {
  const isBartender = provider.provider_type === "bartender";
  const displayPrice =
    provider.min_menu_price && provider.min_menu_price > 0
      ? provider.min_menu_price
      : provider.hourly_rate || 1500;

  const bookingUrl = `/booking?providerId=${provider.provider_id}&date=${eventDate}${
    isComboMode ? "&combo=1" : ""
  }`;

  const specialtyTags = getSpecialtyTags(provider);
  const badgeLabels = getBadgeLabels(provider);

  return (
    <div
      onMouseEnter={onSelect}
      onClick={onSelect}
      className={`group rounded-2xl bg-white border transition-all duration-200 overflow-hidden flex flex-col justify-between cursor-pointer ${
        isSelected
          ? "border-amber-800 ring-2 ring-amber-800/20 shadow-md"
          : "border-stone-200/90 hover:border-amber-800/50 hover:shadow-md"
      }`}
    >
      <div>
        {/* Image Header */}
        <div className="relative h-48 w-full overflow-hidden bg-stone-100">
          <img
            src={
              provider.avatar_url ||
              FALLBACK_AVATARS[index % FALLBACK_AVATARS.length]
            }
            alt={provider.full_name}
            className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-stone-950/75 via-stone-950/15 to-transparent" />

          {/* Top Left: PostGIS Distance & Radius Status */}
          <div className="absolute top-3 left-3 flex flex-wrap items-center gap-1.5">
            <span className="px-2.5 py-1 rounded-full bg-stone-900/90 backdrop-blur-md text-white text-[11px] font-bold flex items-center gap-1 shadow-xs">
              <MapPin className="w-3 h-3 text-amber-400" />
              {provider.distance_km} km
            </span>
            {provider.within_provider_radius ? (
              <span
                className="px-2 py-0.5 rounded-full bg-emerald-600/90 backdrop-blur-md text-white text-[10px] font-bold"
                title={`Şefin ${provider.service_radius_km} km hizmet alanı içindesiniz`}
              >
                ✓ Kapsama Alanında ({provider.service_radius_km}km)
              </span>
            ) : (
              <span
                className="px-2 py-0.5 rounded-full bg-amber-600/90 backdrop-blur-md text-white text-[10px] font-bold"
                title={`Şefin standart yarıçapı ${provider.service_radius_km} km (Ek yol ücreti uygulanabilir)`}
              >
                Menzil: {provider.service_radius_km}km
              </span>
            )}
          </div>

          {/* Top Right: Rating */}
          <div className="absolute top-3 right-3 px-2.5 py-1 rounded-full bg-white/95 backdrop-blur-md text-stone-900 text-xs font-extrabold flex items-center gap-1 shadow-xs">
            <Star className="w-3.5 h-3.5 fill-amber-500 text-amber-500" />
            {Number(provider.rating_avg || 4.9).toFixed(1)}
            <span className="text-[10px] font-normal text-stone-500">
              ({provider.total_reviews || 12})
            </span>
          </div>

          {/* Bottom Overlay: Role & City */}
          <div className="absolute bottom-3 left-3 right-3 flex items-end justify-between text-white">
            <div>
              <span
                className={`inline-block px-2 py-0.5 rounded text-[10px] font-extrabold uppercase tracking-wider mb-1 ${
                  isBartender ? "bg-purple-800/90" : "bg-amber-800/90"
                }`}
              >
                {isBartender ? "🍸 Miksolojist" : "👨‍🍳 Özel Şef"}
              </span>
              <h3 className="font-serif text-lg font-bold leading-tight text-white">
                {provider.full_name}
              </h3>
              <p className="text-[11px] text-stone-200 line-clamp-1">
                {provider.title}
              </p>
            </div>
          </div>
        </div>

        {/* Card Body */}
        <div className="p-4 flex flex-col gap-3">
          {/* Location & Date Availability Row */}
          <div className="flex items-center justify-between text-[11px]">
            <span className="text-stone-500 font-medium truncate">
              📍 {provider.city_region || "İstanbul"}
            </span>
            {provider.available_on_date ? (
              <span className="text-emerald-700 font-bold flex items-center gap-1 shrink-0">
                <CheckCircle2 className="w-3.5 h-3.5" />
                Seçili Tarihte Müsait
              </span>
            ) : (
              <span className="text-rose-600 font-semibold shrink-0">
                Seçili Tarih Dolu
              </span>
            )}
          </div>

          {/* Cuisine & Verification Badges */}
          <div className="flex flex-wrap gap-1.5">
            {specialtyTags.slice(0, 3).map((c: string) => (
              <span
                key={c}
                className="px-2 py-0.5 rounded-md bg-stone-100 text-stone-700 text-[11px] font-semibold"
              >
                {c}
              </span>
            ))}
            {provider.has_ingredients_included && (
              <span className="px-2 py-0.5 rounded-md bg-emerald-50 text-emerald-800 border border-emerald-200 text-[10px] font-bold">
                🛍️ Malzeme Dahil
              </span>
            )}
            {badgeLabels.slice(0, 2).map((b: string) => (
              <span
                key={b}
                className="px-2 py-0.5 rounded-md bg-amber-50 text-amber-900 border border-amber-200/70 text-[10px] font-semibold"
              >
                ✓ {b}
              </span>
            ))}
          </div>

          {/* Combo Package Addon Notice */}
          {isComboMode && !isBartender && (
            <div className="p-2 rounded-xl bg-purple-50 border border-purple-200/80 text-[11px] text-purple-950 flex items-center justify-between">
              <span className="font-semibold">
                🍸 + {featuredMixologistName || "Miksolojist"} Kokteyl Paketi
              </span>
              <Badge className="bg-purple-900 text-white text-[9px]">
                Kombine
              </Badge>
            </div>
          )}
        </div>
      </div>

      {/* Card Footer: Pricing & CTAs */}
      <div className="px-4 py-3 bg-stone-50/80 border-t border-stone-100 flex items-center justify-between gap-2">
        <div>
          <span className="text-[10px] uppercase tracking-wider font-bold text-stone-400 block">
            {provider.min_menu_price ? "Menü Başlangıç" : "Saatlik Ücret"}
          </span>
          <span className="text-base font-extrabold text-stone-900">
            ₺{Number(displayPrice).toLocaleString("tr-TR")}
          </span>
          <span className="text-[11px] text-stone-500">
            {provider.min_menu_price ? " / kişi" : " / saat"}
          </span>
        </div>

        <div className="flex items-center gap-1.5">
          <Link
            href={`/chef/${provider.provider_id}`}
            onClick={(e) => e.stopPropagation()}
            className="px-3 py-2 rounded-xl border border-stone-200 bg-white hover:bg-stone-100 text-stone-800 text-xs font-bold transition-colors"
          >
            Profil
          </Link>
          <Link
            href={bookingUrl}
            onClick={(e) => e.stopPropagation()}
            className="px-3 py-2 rounded-xl bg-amber-800 hover:bg-amber-900 text-white text-xs font-bold flex items-center gap-1 transition-colors shadow-2xs"
          >
            {isComboMode ? "Kombine Seç" : "Rezerve Et"}
            <ArrowRight className="w-3.5 h-3.5" />
          </Link>
        </div>
      </div>
    </div>
  );
}
