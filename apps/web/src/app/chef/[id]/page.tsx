"use client";

import * as React from "react";
import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import {
  ArrowLeft,
  Star,
  ShieldCheck,
  Award,
  MapPin,
  Clock,
  Users,
  Calendar,
  Utensils,
  CheckCircle2,
  Loader2,
  Sparkles,
} from "lucide-react";
import { Header } from "@/components/home/Header";
import { MobileBottomNav } from "@/components/home/MobileBottomNav";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { supabase } from "@/lib/supabase";

interface CourseItem {
  type?: string;
  course?: string;
  name: string;
  description?: string;
}

interface MenuItem {
  id: string;
  title: string;
  description: string;
  category: string;
  pricing_type: string;
  price_per_person: number;
  min_guests: number;
  max_guests: number;
  prep_time_minutes: number;
  ingredients_included: boolean;
  courses: CourseItem[];
  dietary_tags: string[];
  images: string[];
}

interface AvailabilityItem {
  id: string;
  day_of_week?: number | null;
  specific_date?: string | null;
  start_time: string;
  end_time: string;
  is_available: boolean;
}

interface ReviewItem {
  id: string;
  rating_food: number;
  rating_hygiene: number;
  rating_presentation: number;
  rating_overall: number;
  comment: string;
  created_at: string;
  customer?: {
    full_name: string;
    avatar_url?: string;
  };
}

interface ProviderDetailData {
  id: string;
  user_id: string;
  provider_type: "chef" | "bartender" | "both";
  title: string;
  bio: string;
  education?: string;
  experience_years: number;
  city_region: string;
  service_radius_km: number;
  hourly_rate: number;
  min_guests: number;
  max_guests: number;
  portfolio_images: string[];
  is_verified: boolean;
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
  rating_avg: number;
  total_reviews: number;
  user?: {
    full_name: string;
    email: string;
    avatar_url?: string;
  };
}

const DAY_NAMES = ["Pazar", "Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi"];

export default function ChefDetailPage() {
  const params = useParams();
  const router = useRouter();
  const rawId = Array.isArray(params?.id) ? params.id[0] : params?.id;

  const [provider, setProvider] = React.useState<ProviderDetailData | null>(null);
  const [menus, setMenus] = React.useState<MenuItem[]>([]);
  const [availability, setAvailability] = React.useState<AvailabilityItem[]>([]);
  const [reviews, setReviews] = React.useState<ReviewItem[]>([]);
  const [loading, setLoading] = React.useState<boolean>(true);

  // Sticky reservation states
  const [selectedMenuId, setSelectedMenuId] = React.useState<string>("");
  const [bookingMode, setBookingMode] = React.useState<"menu" | "hourly">("menu");
  const [eventDate, setEventDate] = React.useState<string>(() => {
    const tomorrow = new Date(Date.now() + 86400000 * 2);
    return tomorrow.toISOString().split("T")[0];
  });
  const [guestCount, setGuestCount] = React.useState<number>(4);
  const [hoursCount, setHoursCount] = React.useState<number>(4);

  React.useEffect(() => {
    let mounted = true;

    const fetchDetail = async () => {
      setLoading(true);
      try {
        const isUuid =
          typeof rawId === "string" &&
          /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(rawId);

        let providerRow: ProviderDetailData | null = null;

        if (isUuid) {
          const { data } = await supabase
            .from("provider_profiles")
            .select("*, user:profiles(full_name, email, avatar_url)")
            .eq("id", rawId)
            .maybeSingle();
          providerRow = (data as unknown as ProviderDetailData) || null;
        }

        if (!providerRow) {
          const { data: fallbackList } = await supabase
            .from("provider_profiles")
            .select("*, user:profiles(full_name, email, avatar_url)")
            .order("rating_avg", { ascending: false })
            .limit(1);
          providerRow = (fallbackList?.[0] as unknown as ProviderDetailData) || null;
        }

        if (providerRow && mounted) {
          setProvider(providerRow);
          setGuestCount(Math.max(2, providerRow.min_guests || 4));

          const [{ data: menuRows }, { data: availRows }, { data: reviewRows }] =
            await Promise.all([
              supabase
                .from("menus")
                .select("*")
                .eq("provider_id", providerRow.id)
                .eq("is_active", true)
                .order("price_per_person", { ascending: true }),
              supabase
                .from("provider_availability")
                .select("*")
                .eq("provider_id", providerRow.id)
                .order("day_of_week", { ascending: true }),
              supabase
                .from("reviews")
                .select("*, customer:profiles!reviews_customer_id_fkey(full_name, avatar_url)")
                .eq("provider_id", providerRow.id)
                .order("created_at", { ascending: false }),
            ]);

          if (mounted) {
            const loadedMenus = (menuRows as unknown as MenuItem[]) || [];
            setMenus(loadedMenus);
            if (loadedMenus.length > 0) {
              setSelectedMenuId(loadedMenus[0].id);
              setBookingMode("menu");
            } else {
              setBookingMode("hourly");
            }
            setAvailability((availRows as unknown as AvailabilityItem[]) || []);
            setReviews((reviewRows as unknown as ReviewItem[]) || []);
          }
        }
      } catch (e) {
        console.error("Chef detail fetch error:", e);
      } finally {
        if (mounted) setLoading(false);
      }
    };

    fetchDetail();
    return () => {
      mounted = false;
    };
  }, [rawId]);

  if (loading) {
    return (
      <div className="min-h-screen bg-background text-foreground">
        <Header />
        <div className="pt-40 flex items-center justify-center">
          <Loader2 className="w-10 h-10 animate-spin text-secondary" />
        </div>
      </div>
    );
  }

  if (!provider) {
    return (
      <div className="min-h-screen bg-background text-foreground">
        <Header />
        <div className="pt-36 max-w-xl mx-auto text-center px-6 space-y-4">
          <h1 className="font-serif text-2xl font-bold">Sağlayıcı Profili Bulunamadı</h1>
          <Link href="/">
            <Button>Keşfet Ekranına Dön</Button>
          </Link>
        </div>
      </div>
    );
  }

  const selectedMenu = menus.find((m) => m.id === selectedMenuId) || menus[0];
  const estimatedTotal =
    bookingMode === "hourly" || !selectedMenu
      ? Number(provider.hourly_rate || 1200) * hoursCount
      : Number(selectedMenu.price_per_person) * guestCount;

  const gallery =
    provider.portfolio_images && provider.portfolio_images.length > 0
      ? provider.portfolio_images
      : [
          "https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=1000&q=80",
          "https://images.unsplash.com/photo-1559339352-11d035aa65de?auto=format&fit=crop&w=800&q=80",
          "https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?auto=format&fit=crop&w=800&q=80",
        ];

  const handleProceedToBooking = () => {
    const query = new URLSearchParams({
      providerId: provider.id,
      date: eventDate,
      guests: String(guestCount),
      mode: bookingMode,
      hours: String(hoursCount),
    });
    if (selectedMenu && bookingMode === "menu") {
      query.set("menuId", selectedMenu.id);
    }
    router.push(`/booking?${query.toString()}`);
  };

  return (
    <div className="min-h-screen bg-background text-foreground antialiased pb-24 md:pb-16">
      <Header />

      <main className="pt-24 md:pt-28 px-6 md:px-12 max-w-7xl mx-auto w-full">
        {/* Top Back Navigation */}
        <div className="flex items-center justify-between mb-6">
          <Link
            href="/"
            className="flex items-center gap-2 text-sm font-semibold text-foreground hover:opacity-80 transition-opacity"
          >
            <ArrowLeft className="w-4 h-4" /> Keşfet Ekranına Dön
          </Link>
          <div className="flex items-center gap-2 text-xs text-muted-foreground">
            <MapPin className="w-3.5 h-3.5 text-secondary" />
            <span>
              {provider.city_region || "İstanbul"} • {provider.service_radius_km} km hizmet yarıçapı
            </span>
          </div>
        </div>

        {/* Portfolio Gallery */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-3 h-[300px] md:h-[420px] rounded-3xl overflow-hidden mb-10 shadow-sm">
          <div className="md:col-span-2 h-full overflow-hidden">
            <img
              src={gallery[0]}
              alt={provider.user?.full_name || "Portfolyo"}
              className="w-full h-full object-cover hover:scale-105 transition-transform duration-700"
            />
          </div>
          <div className="hidden md:flex flex-col gap-3 h-full">
            <div className="flex-1 overflow-hidden">
              <img
                src={gallery[1] || gallery[0]}
                alt="Sunum 2"
                className="w-full h-full object-cover hover:scale-105 transition-transform duration-700"
              />
            </div>
            <div className="flex-1 overflow-hidden">
              <img
                src={gallery[2] || gallery[0]}
                alt="Sunum 3"
                className="w-full h-full object-cover hover:scale-105 transition-transform duration-700"
              />
            </div>
          </div>
        </div>

        {/* Main Content Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-10">
          {/* Left Column: Profile, Badges, Menus, Availability, Reviews */}
          <div className="lg:col-span-8 space-y-10">
            {/* Chef Header & Hybrid Trust Badges */}
            <div className="flex flex-col sm:flex-row sm:items-start justify-between gap-6 border-b border-border pb-8">
              <div className="space-y-3">
                <div className="flex flex-wrap items-center gap-2">
                  <Badge variant="secondary" className="text-xs font-bold">
                    {provider.provider_type === "bartender"
                      ? "Profesyonel Miksolojist & Barmen"
                      : "Özel Ev Şefi (Private Chef)"}
                  </Badge>
                  <span className="text-xs text-muted-foreground">
                    • {provider.experience_years} Yıl Deneyim
                  </span>
                </div>

                <h1 className="font-serif text-3xl md:text-4xl font-bold text-foreground">
                  {provider.user?.full_name}
                </h1>
                <p className="text-sm font-medium text-secondary">{provider.title}</p>

                <div className="flex flex-wrap items-center gap-3 text-sm pt-1">
                  <span className="flex items-center gap-1 font-bold text-foreground">
                    <Star className="w-4 h-4 fill-secondary text-secondary" />
                    {Number(provider.rating_avg || 5.0).toFixed(2)}
                  </span>
                  <span className="text-muted-foreground">
                    ({provider.total_reviews || reviews.length} doğrulanmış değerlendirme)
                  </span>
                </div>

                {/* Hybrid Trust Badges Row */}
                <div className="flex flex-wrap items-center gap-2 pt-2">
                  {provider.is_verified && (
                    <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-500/10 border border-emerald-500/30 text-emerald-600 text-xs font-bold">
                      <ShieldCheck className="w-3.5 h-3.5" /> Kimlik & Adli Sicil Doğrulanmış
                    </span>
                  )}
                  {provider.verification_badges?.hygiene_cert && (
                    <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-teal-500/10 border border-teal-500/30 text-teal-600 text-xs font-bold">
                      <Award className="w-3.5 h-3.5" /> Hijyen Eğitimi Sertifikalı
                    </span>
                  )}
                  {provider.verification_badges?.diploma && (
                    <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-amber-500/15 border border-amber-500/30 text-amber-600 text-xs font-bold">
                      <Award className="w-3.5 h-3.5" /> Gastronomi Diplomalı Şef
                    </span>
                  )}
                </div>
              </div>

              <img
                src={
                  provider.user?.avatar_url ||
                  gallery[0] ||
                  "https://images.unsplash.com/photo-1577219491135-ce391730fb2c?auto=format&fit=crop&w=400&q=80"
                }
                alt={provider.user?.full_name}
                className="w-24 h-24 rounded-2xl object-cover shadow-md border-2 border-secondary/30 shrink-0"
              />
            </div>

            {/* Bio & Specialties */}
            <div className="border-b border-border pb-8 space-y-4">
              <h2 className="font-serif text-2xl font-bold">Hakkında & Uzmanlık Alanları</h2>
              <p className="text-muted-foreground leading-relaxed text-sm md:text-base">
                {provider.bio}
              </p>
              {provider.education && (
                <p className="text-xs text-muted-foreground">
                  <strong className="text-foreground">Akademik / Mutfak Eğitimi:</strong>{" "}
                  {provider.education}
                </p>
              )}

              <div className="flex flex-wrap gap-2 pt-2">
                {(provider.specialties?.cuisines || []).map((c) => (
                  <Badge key={c} variant="outline">
                    {c}
                  </Badge>
                ))}
                {(provider.specialties?.dietary || []).map((d) => (
                  <Badge key={d} variant="secondary">
                    {d}
                  </Badge>
                ))}
                {(provider.specialties?.cocktails || []).map((ck) => (
                  <Badge key={ck} variant="outline">
                    {ck}
                  </Badge>
                ))}
              </div>
            </div>

            {/* Curated Menus Section */}
            <div className="space-y-6 border-b border-border pb-8">
              <div className="flex items-center justify-between">
                <h2 className="font-serif text-2xl font-bold flex items-center gap-2">
                  <Utensils className="w-5 h-5 text-secondary" /> Tadım Menüleri & Paketler
                </h2>
                <span className="text-xs text-muted-foreground">
                  {menus.length} aktif menü seçeneği
                </span>
              </div>

              {menus.length === 0 ? (
                <div className="p-6 rounded-2xl bg-card border border-border text-sm text-muted-foreground">
                  Bu sağlayıcı saatlik özel hizmet (₺
                  {Number(provider.hourly_rate).toLocaleString("tr-TR")}/saat) sunmaktadır.
                </div>
              ) : (
                <div className="space-y-4">
                  {menus.map((menu) => {
                    const isSelected = selectedMenuId === menu.id && bookingMode === "menu";
                    const courses = Array.isArray(menu.courses) ? menu.courses : [];

                    return (
                      <div
                        key={menu.id}
                        onClick={() => {
                          setSelectedMenuId(menu.id);
                          setBookingMode("menu");
                        }}
                        className={`p-6 rounded-2xl border transition cursor-pointer ${
                          isSelected
                            ? "border-secondary bg-secondary/5 shadow-md"
                            : "border-border bg-card hover:border-secondary/50"
                        }`}
                      >
                        <div className="flex flex-col md:flex-row justify-between items-start gap-4">
                          <div className="space-y-2">
                            <div className="flex flex-wrap items-center gap-2">
                              <h3 className="font-serif font-bold text-lg text-foreground">
                                {menu.title}
                              </h3>
                              <Badge variant="outline" className="text-[11px]">
                                {menu.category}
                              </Badge>
                              {menu.ingredients_included && (
                                <Badge variant="secondary" className="text-[11px]">
                                  ✓ Malzeme Tedariki Dahil
                                </Badge>
                              )}
                            </div>
                            <p className="text-xs md:text-sm text-muted-foreground">
                              {menu.description}
                            </p>
                          </div>

                          <div className="text-left md:text-right shrink-0">
                            <div className="font-serif text-2xl font-bold text-foreground">
                              ₺{Number(menu.price_per_person).toLocaleString("tr-TR")}
                              <span className="text-xs font-normal text-muted-foreground">
                                {" "}
                                / kişi
                              </span>
                            </div>
                            <div className="text-[11px] text-muted-foreground">
                              Min {menu.min_guests} - Maks {menu.max_guests} Misafir
                            </div>
                          </div>
                        </div>

                        {/* Courses Breakdown */}
                        {courses.length > 0 && (
                          <div className="mt-4 pt-4 border-t border-border/60 grid grid-cols-1 sm:grid-cols-2 gap-3">
                            {courses.map((course, idx) => (
                              <div
                                key={idx}
                                className="p-3 rounded-xl bg-background/70 border border-border/50 text-xs"
                              >
                                <div className="font-bold text-secondary uppercase text-[10px]">
                                  {course.type || course.course || `${idx + 1}. Aşama`}
                                </div>
                                <div className="font-semibold text-foreground mt-0.5">
                                  {course.name}
                                </div>
                                {course.description && (
                                  <div className="text-[11px] text-muted-foreground mt-0.5">
                                    {course.description}
                                  </div>
                                )}
                              </div>
                            ))}
                          </div>
                        )}

                        {menu.dietary_tags && menu.dietary_tags.length > 0 && (
                          <div className="flex flex-wrap items-center gap-1.5 mt-3">
                            {menu.dietary_tags.map((dt) => (
                              <span
                                key={dt}
                                className="px-2 py-0.5 rounded-md bg-muted text-[10px] font-medium text-muted-foreground"
                              >
                                {dt}
                              </span>
                            ))}
                          </div>
                        )}
                      </div>
                    );
                  })}
                </div>
              )}
            </div>

            {/* Availability Calendar Section */}
            <div className="space-y-4 border-b border-border pb-8">
              <h2 className="font-serif text-2xl font-bold flex items-center gap-2">
                <Calendar className="w-5 h-5 text-secondary" /> Haftalık Müsaitlik Takvimi
              </h2>
              <div className="grid grid-cols-2 sm:grid-cols-4 md:grid-cols-7 gap-2.5">
                {DAY_NAMES.map((dayName, dayIdx) => {
                  const slot = availability.find((a) => a.day_of_week === dayIdx);
                  const isAvail = slot ? slot.is_available : true;
                  return (
                    <div
                      key={dayName}
                      className={`p-3 rounded-xl border text-center text-xs ${
                        isAvail
                          ? "bg-card border-border text-foreground"
                          : "bg-muted/40 border-border/40 text-muted-foreground opacity-60"
                      }`}
                    >
                      <div className="font-bold">{dayName}</div>
                      <div className="text-[11px] mt-1 text-secondary font-medium">
                        {isAvail
                          ? `${slot?.start_time?.slice(0, 5) || "10:00"} - ${
                              slot?.end_time?.slice(0, 5) || "23:00"
                            }`
                          : "Kapalı"}
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>

            {/* 3-Criteria Customer Reviews Section */}
            <div className="space-y-5">
              <h2 className="font-serif text-2xl font-bold">
                Müşteri Değerlendirmeleri ({reviews.length})
              </h2>

              {reviews.length === 0 ? (
                <p className="text-sm text-muted-foreground">
                  Henüz yazılı değerlendirme bulunmuyor.
                </p>
              ) : (
                <div className="space-y-4">
                  {reviews.map((rev) => (
                    <div
                      key={rev.id}
                      className="p-5 rounded-2xl bg-card border border-border space-y-3"
                    >
                      <div className="flex items-center justify-between">
                        <div className="font-bold text-sm text-foreground">
                          {rev.customer?.full_name || "Doğrulanmış Ev Sahibi"}
                        </div>
                        <div className="flex items-center gap-1 text-xs font-bold text-secondary">
                          <Star className="w-3.5 h-3.5 fill-secondary" />
                          {Number(rev.rating_overall || 5.0).toFixed(1)}
                        </div>
                      </div>

                      <p className="text-xs md:text-sm text-muted-foreground leading-relaxed">
                        {rev.comment}
                      </p>

                      <div className="flex flex-wrap gap-3 pt-2 border-t border-border/60 text-[11px] text-muted-foreground">
                        <span>
                          Lezzet: <strong className="text-foreground">{rev.rating_food}/5</strong>
                        </span>
                        <span>
                          Mutfak Hijyeni:{" "}
                          <strong className="text-foreground">{rev.rating_hygiene}/5</strong>
                        </span>
                        <span>
                          Sunum & İletişim:{" "}
                          <strong className="text-foreground">{rev.rating_presentation}/5</strong>
                        </span>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>

          {/* Right Column: Sticky Booking Configurator Card */}
          <div className="lg:col-span-4">
            <div className="sticky top-28 bg-card border border-border rounded-3xl p-6 shadow-lg space-y-5">
              <div className="flex items-baseline justify-between border-b border-border pb-4">
                <div>
                  <span className="font-serif text-3xl font-bold text-foreground">
                    ₺{estimatedTotal.toLocaleString("tr-TR")}
                  </span>
                  <div className="text-xs text-muted-foreground mt-0.5">
                    Tahmini toplam ({guestCount} misafir)
                  </div>
                </div>
                <Badge variant="secondary" className="text-xs">
                  %100 Escrow Güvencesi
                </Badge>
              </div>

              {/* Service Mode Toggle */}
              <div className="grid grid-cols-2 gap-2 bg-muted/60 p-1 rounded-xl">
                <button
                  type="button"
                  onClick={() => setBookingMode("menu")}
                  className={`py-2 text-xs font-bold rounded-lg transition ${
                    bookingMode === "menu"
                      ? "bg-card text-foreground shadow-xs"
                      : "text-muted-foreground"
                  }`}
                >
                  Kişi Başı Menü
                </button>
                <button
                  type="button"
                  onClick={() => setBookingMode("hourly")}
                  className={`py-2 text-xs font-bold rounded-lg transition ${
                    bookingMode === "hourly"
                      ? "bg-card text-foreground shadow-xs"
                      : "text-muted-foreground"
                  }`}
                >
                  Saatlik (₺{Number(provider.hourly_rate).toLocaleString("tr-TR")}/sa)
                </button>
              </div>

              {/* Date & Guests Selectors */}
              <div className="space-y-3">
                <div className="border border-border p-3 rounded-xl">
                  <label className="text-[10px] font-bold uppercase text-muted-foreground block">
                    Etkinlik Tarihi
                  </label>
                  <input
                    type="date"
                    value={eventDate}
                    onChange={(e) => setEventDate(e.target.value)}
                    className="w-full bg-transparent text-sm font-semibold mt-1 focus:outline-none"
                  />
                </div>

                <div className="border border-border p-3 rounded-xl flex items-center justify-between">
                  <div>
                    <div className="text-[10px] font-bold uppercase text-muted-foreground">
                      Misafir Sayısı
                    </div>
                    <div className="text-sm font-semibold mt-0.5 flex items-center gap-1.5">
                      <Users className="w-4 h-4 text-secondary" /> {guestCount} Kişi
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <button
                      type="button"
                      onClick={() => setGuestCount((g) => Math.max(2, g - 1))}
                      className="w-8 h-8 rounded-lg bg-muted font-bold text-sm"
                    >
                      -
                    </button>
                    <button
                      type="button"
                      onClick={() => setGuestCount((g) => Math.min(30, g + 1))}
                      className="w-8 h-8 rounded-lg bg-muted font-bold text-sm"
                    >
                      +
                    </button>
                  </div>
                </div>

                {bookingMode === "hourly" && (
                  <div className="border border-border p-3 rounded-xl flex items-center justify-between">
                    <div>
                      <div className="text-[10px] font-bold uppercase text-muted-foreground">
                        Kiralama Süresi
                      </div>
                      <div className="text-sm font-semibold mt-0.5 flex items-center gap-1.5">
                        <Clock className="w-4 h-4 text-secondary" /> {hoursCount} Saat
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      <button
                        type="button"
                        onClick={() => setHoursCount((h) => Math.max(2, h - 1))}
                        className="w-8 h-8 rounded-lg bg-muted font-bold text-sm"
                      >
                        -
                      </button>
                      <button
                        type="button"
                        onClick={() => setHoursCount((h) => Math.min(12, h + 1))}
                        className="w-8 h-8 rounded-lg bg-muted font-bold text-sm"
                      >
                        +
                      </button>
                    </div>
                  </div>
                )}
              </div>

              <Button
                onClick={handleProceedToBooking}
                className="w-full py-6 text-sm font-bold rounded-xl gap-2 cursor-pointer"
              >
                <Sparkles className="w-4 h-4" />
                Rezervasyon Sihirbazına Geç
              </Button>

              <div className="space-y-1.5 text-[11px] text-muted-foreground pt-1">
                <div className="flex items-center gap-1.5">
                  <CheckCircle2 className="w-3.5 h-3.5 text-emerald-500 shrink-0" />
                  <span>Ödemeniz hizmet tamamlanana kadar Escrow havuzunda korunur.</span>
                </div>
                <div className="flex items-center gap-1.5">
                  <CheckCircle2 className="w-3.5 h-3.5 text-emerald-500 shrink-0" />
                  <span>Sonraki adımda mutfak uygunluk anketi ve Barmen Upsell seçebilirsiniz.</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </main>

      <MobileBottomNav />
    </div>
  );
}
