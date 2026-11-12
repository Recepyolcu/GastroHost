"use client";

import * as React from "react";
import Link from "next/link";
import {
  MapPin,
  Star,
  ShieldCheck,
  Award,
  Navigation,
  Maximize2,
  Minimize2,
  X,
  CheckCircle2,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";

export interface GeoProviderItem {
  provider_id: string;
  user_id: string;
  full_name: string;
  avatar_url?: string | null;
  provider_type: "chef" | "bartender" | "both";
  title?: string | null;
  bio?: string | null;
  city_region?: string | null;
  service_radius_km: number;
  hourly_rate: number;
  min_menu_price: number;
  has_ingredients_included: boolean;
  rating_avg: number;
  total_reviews: number;
  is_verified: boolean;
  is_available_now: boolean;
  verification_badges?: {
    identity?: boolean;
    criminal_record?: boolean;
    hygiene_cert?: boolean;
    diploma?: boolean;
  };
  specialties?: {
    cuisines?: string[];
    dietary?: string[];
    cocktails?: string[];
  };
  portfolio_images?: string[];
  lat: number;
  lng: number;
  distance_km: number;
  within_provider_radius: boolean;
  available_on_date: boolean;
}

interface InteractiveDiscoveryMapProps {
  userLat: number;
  userLng: number;
  userLabel: string;
  searchRadiusKm: number;
  providers: GeoProviderItem[];
  selectedProviderId: string | null;
  onSelectProvider: (id: string | null) => void;
  onPickUserLocation?: (lat: number, lng: number, label: string) => void;
  eventDate?: string;
  isComboMode?: boolean;
}

declare global {
  interface Window {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    L?: any;
  }
}

export function InteractiveDiscoveryMap({
  userLat,
  userLng,
  userLabel,
  searchRadiusKm,
  providers,
  selectedProviderId,
  onSelectProvider,
  onPickUserLocation,
  eventDate,
  isComboMode,
}: InteractiveDiscoveryMapProps) {
  const mapContainerRef = React.useRef<HTMLDivElement | null>(null);
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const mapInstanceRef = React.useRef<any>(null);
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const layerGroupRef = React.useRef<any>(null);

  const [leafletReady, setLeafletReady] = React.useState<boolean>(false);
  const [isExpanded, setIsExpanded] = React.useState<boolean>(false);
  const [pickLocationMode, setPickLocationMode] = React.useState<boolean>(false);

  // Load Leaflet CSS & JS from CDN once
  React.useEffect(() => {
    if (typeof window === "undefined") return;

    if (window.L) {
      setLeafletReady(true);
      return;
    }

    const existingCss = document.getElementById("leaflet-css-cdn");
    if (!existingCss) {
      const link = document.createElement("link");
      link.id = "leaflet-css-cdn";
      link.rel = "stylesheet";
      link.href = "https://unpkg.com/leaflet@1.9.4/dist/leaflet.css";
      document.head.appendChild(link);
    }

    const existingScript = document.getElementById("leaflet-js-cdn") as HTMLScriptElement | null;
    if (existingScript) {
      existingScript.addEventListener("load", () => setLeafletReady(true));
      return;
    }

    const script = document.createElement("script");
    script.id = "leaflet-js-cdn";
    script.src = "https://unpkg.com/leaflet@1.9.4/dist/leaflet.js";
    script.async = true;
    script.onload = () => setLeafletReady(true);
    document.body.appendChild(script);
  }, []);

  // Initialize Map instance
  React.useEffect(() => {
    if (!leafletReady || !mapContainerRef.current || !window.L) return;

    const L = window.L;
    if (!mapInstanceRef.current) {
      const map = L.map(mapContainerRef.current, {
        center: [userLat, userLng],
        zoom: 12,
        zoomControl: true,
      });

      L.tileLayer("https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png", {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
        maxZoom: 19,
      }).addTo(map);

      layerGroupRef.current = L.layerGroup().addTo(map);
      mapInstanceRef.current = map;
    }

    return () => {
      if (mapInstanceRef.current) {
        mapInstanceRef.current.remove();
        mapInstanceRef.current = null;
        layerGroupRef.current = null;
      }
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [leafletReady]);

  // Handle map click when "Haritadan Konum Seç" mode is active
  React.useEffect(() => {
    if (!mapInstanceRef.current || !window.L) return;
    const map = mapInstanceRef.current;

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const handleMapClick = async (e: any) => {
      if (!pickLocationMode || !onPickUserLocation) return;
      const { lat, lng } = e.latlng;
      let label = `Seçilen Konum (${lat.toFixed(3)}, ${lng.toFixed(3)})`;
      try {
        const res = await fetch(
          `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}`
        );
        const data = await res.json();
        const district =
          data.address?.suburb ||
          data.address?.town ||
          data.address?.city_district ||
          "İstanbul";
        const road = data.address?.road || "";
        label = road ? `${road}, ${district}` : `${district}, İstanbul`;
      } catch {
        // fallback coordinate label
      }
      onPickUserLocation(lat, lng, label);
      setPickLocationMode(false);
    };

    map.on("click", handleMapClick);
    return () => {
      map.off("click", handleMapClick);
    };
  }, [pickLocationMode, onPickUserLocation]);

  // Render user pin, PostGIS ST_DWithin circle, and provider markers
  React.useEffect(() => {
    if (!leafletReady || !mapInstanceRef.current || !layerGroupRef.current || !window.L) return;
    const L = window.L;
    const map = mapInstanceRef.current;
    const group = layerGroupRef.current;

    group.clearLayers();

    // 1. User Location Pin
    const userIcon = L.divIcon({
      className: "gastrohost-user-pin",
      html: `
        <div style="display:flex;align-items:center;justify-content:center;width:36px;height:36px;border-radius:9999px;background:#0f172a;border:3px solid #f59e0b;box-shadow:0 6px 16px rgba(0,0,0,0.35);color:#f59e0b;font-weight:800;font-size:11px;">
          SİZ
        </div>
      `,
      iconSize: [36, 36],
      iconAnchor: [18, 18],
    });

    L.marker([userLat, userLng], { icon: userIcon })
      .bindTooltip(`Konumunuz: ${userLabel}`, { direction: "top" })
      .addTo(group);

    // 2. PostGIS Search Radius Circle (ST_DWithin)
    L.circle([userLat, userLng], {
      radius: Math.min(searchRadiusKm, 35) * 1000,
      color: "#d97706",
      weight: 1.5,
      dashArray: "6 6",
      fillColor: "#f59e0b",
      fillOpacity: 0.06,
    }).addTo(group);

    // 3. Provider Pins
    providers.forEach((prov) => {
      if (!prov.lat || !prov.lng) return;
      const isSelected = prov.provider_id === selectedProviderId;
      const isBartender = prov.provider_type === "bartender";
      const priceText = `₺${Number(prov.min_menu_price || prov.hourly_rate).toLocaleString("tr-TR")}`;
      const bg = isSelected
        ? "#d97706"
        : isBartender
        ? "#4f46e5"
        : "#0f172a";
      const border = isSelected ? "#ffffff" : "#f59e0b";

      const pinIcon = L.divIcon({
        className: "gastrohost-provider-pin",
        html: `
          <div style="
            display:inline-flex;
            align-items:center;
            gap:5px;
            padding:5px 10px;
            border-radius:9999px;
            background:${bg};
            color:#ffffff;
            border:2px solid ${border};
            font-family:'DM Sans Variable', sans-serif;
            font-size:11px;
            font-weight:700;
            white-space:nowrap;
            box-shadow:0 6px 16px rgba(0,0,0,0.28);
            transform:${isSelected ? "scale(1.14)" : "scale(1)"};
            transition:transform 0.2s ease;
            cursor:pointer;
          ">
            <span>${isBartender ? "🍸" : "👨‍🍳"} ${priceText}</span>
            <span style="color:#fbbf24;">★${Number(prov.rating_avg || 5).toFixed(1)}</span>
          </div>
        `,
        iconSize: [110, 32],
        iconAnchor: [55, 16],
      });

      const marker = L.marker([prov.lat, prov.lng], { icon: pinIcon }).addTo(group);
      marker.on("click", () => {
        onSelectProvider(prov.provider_id);
      });

      // If this provider is selected, also draw their service_radius_km coverage circle
      if (isSelected) {
        L.circle([prov.lat, prov.lng], {
          radius: (prov.service_radius_km || 15) * 1000,
          color: "#10b981",
          weight: 2,
          fillColor: "#10b981",
          fillOpacity: 0.08,
        }).addTo(group);
      }
    });

    // Pan smoothly to selected provider or user location
    const selectedProv = providers.find((p) => p.provider_id === selectedProviderId);
    if (selectedProv && selectedProv.lat && selectedProv.lng) {
      map.flyTo([selectedProv.lat, selectedProv.lng], 13, { duration: 0.6 });
    } else {
      map.flyTo([userLat, userLng], 12, { duration: 0.6 });
    }
  }, [
    leafletReady,
    userLat,
    userLng,
    userLabel,
    searchRadiusKm,
    providers,
    selectedProviderId,
    onSelectProvider,
  ]);

  // Trigger map invalidateSize when expanding/collapsing
  React.useEffect(() => {
    if (mapInstanceRef.current) {
      setTimeout(() => {
        mapInstanceRef.current.invalidateSize();
      }, 200);
    }
  }, [isExpanded]);

  const activeProvider = providers.find((p) => p.provider_id === selectedProviderId) || null;

  return (
    <div
      className={`relative isolate z-10 rounded-3xl overflow-hidden border border-border shadow-md bg-card transition-all ${
        isExpanded ? "h-[680px]" : "h-[520px]"
      }`}
    >
      {/* Top Map Controls Overlay */}
      <div className="absolute top-3.5 left-3.5 right-3.5 z-[400] flex flex-wrap items-center justify-between gap-2 pointer-events-none">
        <div className="pointer-events-auto flex flex-wrap items-center gap-2 bg-white/95 backdrop-blur-md px-3.5 py-2 rounded-2xl border border-stone-200 shadow-md text-xs">
          <span className="flex items-center gap-1.5 font-bold text-stone-900">
            <MapPin className="w-3.5 h-3.5 text-amber-800" />
            {searchRadiusKm} km Arama Alanı
          </span>
          <span className="text-stone-400">•</span>
          <span className="font-semibold text-emerald-700">
            {providers.length} Profesyonel Haritada
          </span>
        </div>

        <div className="pointer-events-auto flex items-center gap-2">
          {onPickUserLocation && (
            <button
              type="button"
              onClick={() => setPickLocationMode((prev) => !prev)}
              className={`px-3 py-2 rounded-xl text-xs font-bold border shadow-md transition flex items-center gap-1.5 cursor-pointer ${
                pickLocationMode
                  ? "bg-amber-800 text-white border-amber-800 animate-pulse"
                  : "bg-white/95 text-stone-900 border-stone-200 hover:bg-stone-100"
              }`}
            >
              <Navigation className="w-3.5 h-3.5" />
              {pickLocationMode ? "Haritada Bir Noktaya Tıklayın..." : "Haritadan Konum Seç"}
            </button>
          )}

          <button
            type="button"
            onClick={() => setIsExpanded((prev) => !prev)}
            className="p-2 rounded-xl bg-white/95 border border-stone-200 shadow-md text-stone-900 hover:bg-stone-100 transition cursor-pointer"
            title={isExpanded ? "Küçült" : "Haritayı Büyüt"}
          >
            {isExpanded ? <Minimize2 className="w-4 h-4" /> : <Maximize2 className="w-4 h-4" />}
          </button>
        </div>
      </div>

      {/* Leaflet Map Canvas */}
      <div ref={mapContainerRef} className="w-full h-full z-10" />

      {/* Bottom Floating Selected Provider Preview Card */}
      {activeProvider && (
        <div className="absolute bottom-4 left-4 right-4 z-[400] bg-white border border-amber-700/60 rounded-2xl p-4 shadow-2xl flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div className="flex items-center gap-3.5">
            <img
              src={
                activeProvider.avatar_url ||
                activeProvider.portfolio_images?.[0] ||
                "https://images.unsplash.com/photo-1577219491135-ce391730fb2c?auto=format&fit=crop&w=300&q=80"
              }
              alt={activeProvider.full_name}
              className="w-16 h-16 rounded-2xl object-cover shrink-0 border border-border"
            />
            <div className="space-y-1">
              <div className="flex flex-wrap items-center gap-2">
                <span className="font-serif font-bold text-base text-foreground">
                  {activeProvider.full_name}
                </span>
                <Badge variant="secondary" className="text-[10px]">
                  {activeProvider.distance_km} km uzaklıkta
                </Badge>
                {activeProvider.available_on_date && (
                  <span className="inline-flex items-center gap-1 text-[10px] font-bold text-emerald-600 bg-emerald-500/10 px-2 py-0.5 rounded-full">
                    <CheckCircle2 className="w-3 h-3" /> Tarihte Müsait
                  </span>
                )}
              </div>

              <p className="text-xs text-secondary font-medium line-clamp-1">
                {activeProvider.title} • Hizmet Yarıçapı: {activeProvider.service_radius_km} km
              </p>

              <div className="flex flex-wrap items-center gap-2 text-xs">
                <span className="flex items-center gap-1 font-bold text-foreground">
                  <Star className="w-3.5 h-3.5 fill-secondary text-secondary" />
                  {Number(activeProvider.rating_avg || 5.0).toFixed(1)} (
                  {activeProvider.total_reviews})
                </span>
                {activeProvider.is_verified && (
                  <span className="text-emerald-600 font-semibold flex items-center gap-0.5 text-[11px]">
                    <ShieldCheck className="w-3.5 h-3.5" /> Onaylı
                  </span>
                )}
                {activeProvider.verification_badges?.diploma && (
                  <span className="text-amber-600 font-semibold flex items-center gap-0.5 text-[11px]">
                    <Award className="w-3.5 h-3.5" /> Diplomalı
                  </span>
                )}
              </div>
            </div>
          </div>

          <div className="flex items-center gap-2 w-full sm:w-auto justify-end">
            <div className="text-right mr-2 hidden md:block">
              <div className="font-sans font-bold tabular-nums tracking-tight text-lg text-foreground">
                ₺{Number(activeProvider.min_menu_price || activeProvider.hourly_rate || 0).toLocaleString("tr-TR")}
              </div>
              <div className="text-[10px] text-muted-foreground">
                {Number(activeProvider.min_menu_price) > 0 ? "/ kişi başı" : "/ saat"}
              </div>
            </div>

            <Link href={`/chef/${activeProvider.provider_id}`}>
              <Button size="sm" variant="outline" className="rounded-xl text-xs font-semibold">
                Profili Aç
              </Button>
            </Link>
            <Link
              href={`/booking?providerId=${activeProvider.provider_id}${
                eventDate ? `&date=${eventDate}` : ""
              }${isComboMode ? "&combo=1" : ""}`}
            >
              <Button size="sm" className="rounded-xl text-xs font-bold">
                Rezerve Et
              </Button>
            </Link>
            <button
              type="button"
              onClick={() => onSelectProvider(null)}
              className="p-1.5 rounded-lg hover:bg-muted text-muted-foreground"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

