"use client";

import * as React from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import {
  ArrowLeft,
  Calendar,
  ShieldCheck,
  ShoppingBag,
  Wine,
  Utensils,
  CheckCircle2,
  Loader2,
  AlertCircle,
  MapPin,
  Sparkles,
} from "lucide-react";
import { Header } from "@/components/home/Header";
import { MobileBottomNav } from "@/components/home/MobileBottomNav";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { supabase, DEFAULT_COMMISSION_RATE } from "@/lib/supabase";
import { useAuth } from "@/lib/auth-context";

interface MenuOption {
  id: string;
  title: string;
  price_per_person: number;
  ingredients_included: boolean;
  procurement_items?: { item?: string; name?: string; quantity?: string }[];
}

interface BartenderUpsellOption {
  id: string;
  title: string;
  hourly_rate: number;
  user?: { full_name: string; avatar_url?: string };
  menus?: { id: string; title: string; price_per_person: number }[];
}

const ALLERGEN_OPTIONS = [
  "Glüten / Çölyak",
  "Laktoz Hassasiyeti",
  "Kabuklu Deniz Ürünleri",
  "Yer Fıstığı & Kuruyemiş",
  "Yumurta Alerjisi",
  "Vegan / Vejetaryen Misafir",
];

function BookingWizardContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { userProfile, userLocation } = useAuth();

  const paramProviderId = searchParams.get("providerId");
  const paramMenuId = searchParams.get("menuId");
  const paramDate = searchParams.get("date");
  const paramGuests = searchParams.get("guests");
  const paramMode = searchParams.get("mode");
  const paramHours = searchParams.get("hours");
  const paramCombo = searchParams.get("combo");

  const [step, setStep] = React.useState<number>(1);
  const [loading, setLoading] = React.useState<boolean>(true);
  const [submitting, setSubmitting] = React.useState<boolean>(false);
  const [errorMsg, setErrorMsg] = React.useState<string | null>(null);

  const [provider, setProvider] = React.useState<{
    id: string;
    title: string;
    hourly_rate: number;
    provider_type: string;
    user?: { full_name: string; avatar_url?: string };
  } | null>(null);
  const [menus, setMenus] = React.useState<MenuOption[]>([]);
  const [bartenders, setBartenders] = React.useState<BartenderUpsellOption[]>([]);

  // Step 1 State: Date, Time, Guests, Mode, Address
  const [isHourly, setIsHourly] = React.useState<boolean>(paramMode === "hourly");
  const [selectedMenuId, setSelectedMenuId] = React.useState<string>(paramMenuId || "");
  const [eventDate, setEventDate] = React.useState<string>(
    paramDate || new Date(Date.now() + 86400000 * 3).toISOString().split("T")[0]
  );
  const [eventTime, setEventTime] = React.useState<string>("19:30");
  const [guestCount, setGuestCount] = React.useState<number>(Number(paramGuests) || 4);
  const [hoursCount, setHoursCount] = React.useState<number>(Number(paramHours) || 4);
  const [eventAddress, setEventAddress] = React.useState<string>(
    userProfile?.default_address || "Caferağa Mah. Moda Cad. No: 42 D: 5, Kadıköy / İstanbul"
  );
  const [notes, setNotes] = React.useState<string>("");

  // Step 2 State: Kitchen Survey & Allergens
  const [stoveType, setStoveType] = React.useState<"gas" | "induction" | "electric">("gas");
  const [hasOven, setHasOven] = React.useState<boolean>(true);
  const [hasBlender, setHasBlender] = React.useState<boolean>(true);
  const [hasIceMaker, setHasIceMaker] = React.useState<boolean>(false);
  const [selectedAllergies, setSelectedAllergies] = React.useState<string[]>([]);

  // Step 3 State: Ingredients Sourcing
  const [ingredientsIncluded, setIngredientsIncluded] = React.useState<boolean>(true);

  // Step 4 State: Bartender Upsell
  const [selectedBartenderId, setSelectedBartenderId] = React.useState<string | null>(null);

  React.useEffect(() => {
    if (userProfile?.default_address) {
      setEventAddress(userProfile.default_address);
    }
  }, [userProfile?.default_address]);

  React.useEffect(() => {
    let mounted = true;

    const loadBookingContext = async () => {
      setLoading(true);
      try {
        let targetProvider = null;

        if (paramProviderId) {
          const { data } = await supabase
            .from("provider_profiles")
            .select("id, title, hourly_rate, provider_type, user:profiles(full_name, avatar_url)")
            .eq("id", paramProviderId)
            .maybeSingle();
          targetProvider = data;
        }

        if (!targetProvider) {
          const { data: firstChef } = await supabase
            .from("provider_profiles")
            .select("id, title, hourly_rate, provider_type, user:profiles(full_name, avatar_url)")
            .in("provider_type", ["chef", "both"])
            .limit(1);
          targetProvider = firstChef?.[0] || null;
        }

        if (targetProvider && mounted) {
          setProvider(targetProvider as unknown as typeof provider);

          const [{ data: menuRows }, { data: bartenderRows }] = await Promise.all([
            supabase
              .from("menus")
              .select("id, title, price_per_person, ingredients_included, procurement_items")
              .eq("provider_id", targetProvider.id)
              .eq("is_active", true),
            supabase
              .from("provider_profiles")
              .select(
                "id, title, hourly_rate, user:profiles(full_name, avatar_url), menus:menus(id, title, price_per_person)"
              )
              .in("provider_type", ["bartender", "both"])
              .neq("id", targetProvider.id),
          ]);

          if (mounted) {
            const mList = (menuRows as unknown as MenuOption[]) || [];
            setMenus(mList);
            if (!paramMenuId && mList.length > 0) {
              setSelectedMenuId(mList[0].id);
            }
            const bList = (bartenderRows as unknown as BartenderUpsellOption[]) || [];
            setBartenders(bList);
            if (paramCombo === "1" && bList.length > 0) {
              setSelectedBartenderId(bList[0].id);
            }
          }
        }
      } catch (e) {
        console.error("Error loading booking wizard data:", e);
      } finally {
        if (mounted) setLoading(false);
      }
    };

    loadBookingContext();
    return () => {
      mounted = false;
    };
  }, [paramProviderId, paramMenuId, paramCombo]);

  const toggleAllergy = (item: string) => {
    setSelectedAllergies((prev) =>
      prev.includes(item) ? prev.filter((x) => x !== item) : [...prev, item]
    );
  };

  const activeMenu = menus.find((m) => m.id === selectedMenuId) || menus[0];
  const baseUnitPrice = isHourly
    ? Number(provider?.hourly_rate || 1200)
    : Number(activeMenu?.price_per_person || 1800);

  const baseServiceTotal = isHourly ? baseUnitPrice * hoursCount : baseUnitPrice * guestCount;
  const ingredientDiscount = !ingredientsIncluded ? Math.round(baseServiceTotal * 0.2) : 0;

  const selectedBartender = bartenders.find((b) => b.id === selectedBartenderId);
  const bartenderMenu = selectedBartender?.menus?.[0];
  const addonPrice = selectedBartender
    ? bartenderMenu
      ? Number(bartenderMenu.price_per_person) * guestCount
      : Number(selectedBartender.hourly_rate || 1200) * 3
    : 0;

  const totalPrice = Math.max(500, baseServiceTotal - ingredientDiscount + addonPrice);
  const platformFee = Math.round(totalPrice * DEFAULT_COMMISSION_RATE * 100) / 100; // %10
  const providerEarnings = Math.round((totalPrice - platformFee) * 100) / 100; // %90

  const handleCompleteEscrowBooking = async () => {
    if (!provider) return;
    setErrorMsg(null);
    setSubmitting(true);

    try {
      const customerId = userProfile?.id || "11111111-2222-4333-8444-555555550006";
      const bookingCode = `GH-${Math.floor(10000 + Math.random() * 90000)}`;

      const defaultProcurement =
        activeMenu?.procurement_items && activeMenu.procurement_items.length > 0
          ? activeMenu.procurement_items
          : [
              { item: "Mevsimsel Organik Sebze & Yeşillikler", quantity: "2 kg", status: "purchased" },
              { item: "Özel Kesim Dinlendirilmiş Ana Ürün", quantity: `${guestCount} porsiyon`, status: "purchased" },
              { item: "El Yapımı Sos & Garnitür Malzemeleri", quantity: "Tam Set", status: "purchased" },
            ];

      const { data: insertedBooking, error: bookingErr } = await supabase
        .from("bookings")
        .insert({
          booking_code: bookingCode,
          customer_id: customerId,
          provider_id: provider.id,
          menu_id: !isHourly && activeMenu ? activeMenu.id : null,
          addon_bartender_id: selectedBartender?.id || null,
          addon_menu_id: bartenderMenu?.id || null,
          addon_price: addonPrice,
          event_date: eventDate,
          event_time: `${eventTime}:00`,
          guest_count: guestCount,
          is_hourly: isHourly,
          hours_count: hoursCount,
          ingredients_included: ingredientsIncluded,
          procurement_items: defaultProcurement,
          unit_price: baseUnitPrice,
          total_price: totalPrice,
          commission_rate: DEFAULT_COMMISSION_RATE,
          platform_fee: platformFee,
          provider_earnings: providerEarnings,
          status: "accepted",
          kitchen_details: {
            stove_type: stoveType,
            has_oven: hasOven,
            has_blender: hasBlender,
            has_ice_maker: hasIceMaker,
          },
          allergies: selectedAllergies,
          notes: notes.trim() || null,
          event_address: eventAddress.trim() || userLocation.label,
          accepted_at: new Date().toISOString(),
        })
        .select("id")
        .single();

      if (bookingErr || !insertedBooking) {
        throw new Error(bookingErr?.message || "Rezervasyon oluşturulamadı.");
      }

      // Call process_escrow_payment RPC (%10 commission, %90 payout held in escrow)
      await supabase.rpc("process_escrow_payment", {
        p_booking_id: insertedBooking.id,
        p_customer_id: customerId,
        p_provider_id: provider.id,
        p_amount: totalPrice,
        p_commission_rate: DEFAULT_COMMISSION_RATE,
        p_gateway: "iyzico",
      });

      router.push(`/tracker?bookingId=${insertedBooking.id}`);
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : "Ödeme işlemi sırasında hata oluştu.";
      setErrorMsg(msg);
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) {
    return (
      <div className="pt-36 flex items-center justify-center">
        <Loader2 className="w-8 h-8 animate-spin text-secondary" />
      </div>
    );
  }

  return (
    <main className="pt-24 md:pt-28 px-6 md:px-12 max-w-6xl mx-auto w-full">
      {/* Top Header & Step Progress */}
      <div className="mb-8 space-y-4">
        <Link
          href={provider ? `/chef/${provider.id}` : "/"}
          className="inline-flex items-center gap-2 text-sm font-semibold text-foreground hover:opacity-80"
        >
          <ArrowLeft className="w-4 h-4" /> Şef Detayına Dön
        </Link>

        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <h1 className="font-serif text-3xl md:text-4xl font-bold">
              5 Adımlı Rezervasyon & Escrow Sihirbazı
            </h1>
            <p className="text-sm text-muted-foreground mt-1">
              {provider?.user?.full_name} ile evinizde güvenli gastronomi deneyimi
            </p>
          </div>

          {/* 5-Step Indicator */}
          <div className="flex items-center gap-1.5">
            {[
              { num: 1, title: "Tarih & Menü" },
              { num: 2, title: "Mutfak & Alerjen" },
              { num: 3, title: "Malzeme Tedarik" },
              { num: 4, title: "Barmen Upsell" },
              { num: 5, title: "Escrow Ödeme" },
            ].map((s) => (
              <button
                key={s.num}
                type="button"
                onClick={() => setStep(s.num)}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold transition cursor-pointer ${
                  step === s.num
                    ? "bg-primary text-primary-foreground shadow-sm"
                    : step > s.num
                    ? "bg-emerald-500/15 text-emerald-600"
                    : "bg-muted text-muted-foreground"
                }`}
              >
                {s.num}. {s.title}
              </button>
            ))}
          </div>
        </div>
      </div>

      {errorMsg && (
        <div className="mb-6 p-4 rounded-2xl bg-destructive/10 border border-destructive/30 text-destructive text-xs font-semibold flex items-center gap-2">
          <AlertCircle className="w-4 h-4 shrink-0" />
          <span>{errorMsg}</span>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
        {/* Left Column: Active Wizard Step */}
        <div className="lg:col-span-7 space-y-6">
          {/* STEP 1: Date, Time, Guests, Menu vs Hourly & Address */}
          {step === 1 && (
            <div className="bg-card border border-border p-6 md:p-8 rounded-2xl shadow-sm space-y-6">
              <div className="flex items-center gap-2.5">
                <Calendar className="w-5 h-5 text-secondary" />
                <h2 className="font-serif text-xl font-bold">
                  Adım 1: Tarih, Kişi Sayısı ve Menü Seçimi
                </h2>
              </div>

              <div className="grid grid-cols-2 gap-3 bg-muted/60 p-1.5 rounded-xl">
                <button
                  type="button"
                  onClick={() => setIsHourly(false)}
                  className={`py-2.5 rounded-lg text-xs font-bold transition ${
                    !isHourly ? "bg-card text-foreground shadow-xs" : "text-muted-foreground"
                  }`}
                >
                  Kişi Başı Tadım Menüsü
                </button>
                <button
                  type="button"
                  onClick={() => setIsHourly(true)}
                  className={`py-2.5 rounded-lg text-xs font-bold transition ${
                    isHourly ? "bg-card text-foreground shadow-xs" : "text-muted-foreground"
                  }`}
                >
                  Saatlik Özel Şef (₺{Number(provider?.hourly_rate || 1200).toLocaleString("tr-TR")}/sa)
                </button>
              </div>

              {!isHourly && menus.length > 0 && (
                <div className="space-y-2">
                  <label className="text-xs font-bold uppercase text-muted-foreground block">
                    Menü Seçiniz
                  </label>
                  <div className="space-y-2">
                    {menus.map((m) => (
                      <div
                        key={m.id}
                        onClick={() => setSelectedMenuId(m.id)}
                        className={`p-3.5 rounded-xl border flex items-center justify-between cursor-pointer transition ${
                          selectedMenuId === m.id
                            ? "border-secondary bg-secondary/10"
                            : "border-border hover:border-secondary/40"
                        }`}
                      >
                        <div>
                          <div className="font-bold text-sm">{m.title}</div>
                          <div className="text-xs text-muted-foreground">
                            {m.ingredients_included ? "Malzeme Dahil" : "Malzeme Hariç"}
                          </div>
                        </div>
                        <div className="font-serif font-bold text-base text-secondary">
                          ₺{Number(m.price_per_person).toLocaleString("tr-TR")} / kişi
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <div>
                  <label className="text-xs font-bold uppercase text-muted-foreground block mb-1.5">
                    Etkinlik Tarihi
                  </label>
                  <Input
                    type="date"
                    value={eventDate}
                    onChange={(e) => setEventDate(e.target.value)}
                  />
                </div>
                <div>
                  <label className="text-xs font-bold uppercase text-muted-foreground block mb-1.5">
                    Başlangıç Saati
                  </label>
                  <Input
                    type="time"
                    value={eventTime}
                    onChange={(e) => setEventTime(e.target.value)}
                  />
                </div>
                <div>
                  <label className="text-xs font-bold uppercase text-muted-foreground block mb-1.5">
                    {isHourly ? "Süre (Saat)" : "Misafir Sayısı"}
                  </label>
                  <Input
                    type="number"
                    min={2}
                    max={30}
                    value={isHourly ? hoursCount : guestCount}
                    onChange={(e) =>
                      isHourly
                        ? setHoursCount(Math.max(2, Number(e.target.value)))
                        : setGuestCount(Math.max(2, Number(e.target.value)))
                    }
                  />
                </div>
              </div>

              <div>
                <label className="text-xs font-bold uppercase text-muted-foreground block mb-1.5">
                  Etkinlik Adresi
                </label>
                <div className="relative">
                  <MapPin className="w-4 h-4 text-secondary absolute left-3 top-3" />
                  <Input
                    value={eventAddress}
                    onChange={(e) => setEventAddress(e.target.value)}
                    className="pl-9"
                    placeholder="Açık adresiniz..."
                  />
                </div>
              </div>

              <div className="flex justify-end">
                <Button onClick={() => setStep(2)} className="rounded-xl px-6 font-bold">
                  Adım 2: Mutfak & Alerjen Kontrolü →
                </Button>
              </div>
            </div>
          )}

          {/* STEP 2: Kitchen Suitability Survey & Allergens */}
          {step === 2 && (
            <div className="bg-card border border-border p-6 md:p-8 rounded-2xl shadow-sm space-y-6">
              <div className="flex items-center gap-2.5">
                <Utensils className="w-5 h-5 text-secondary" />
                <h2 className="font-serif text-xl font-bold">
                  Adım 2: Mutfak Donanım Anketi & Alerjenler
                </h2>
              </div>

              <div>
                <label className="text-xs font-bold uppercase text-muted-foreground block mb-2">
                  Ocak Tipi
                </label>
                <div className="grid grid-cols-3 gap-3">
                  {[
                    { id: "gas", label: "Gazlı Ocak" },
                    { id: "induction", label: "İndüksiyon" },
                    { id: "electric", label: "Elektrikli / Seramik" },
                  ].map((st) => (
                    <button
                      key={st.id}
                      type="button"
                      onClick={() => setStoveType(st.id as typeof stoveType)}
                      className={`p-3 rounded-xl border text-xs font-bold transition ${
                        stoveType === st.id
                          ? "border-secondary bg-secondary/15 text-foreground"
                          : "border-border text-muted-foreground"
                      }`}
                    >
                      {st.label}
                    </button>
                  ))}
                </div>
              </div>

              <div className="space-y-2.5">
                <label className="text-xs font-bold uppercase text-muted-foreground block">
                  Mutfak Ekipman Uygunluğu
                </label>
                <label className="flex items-center gap-3 p-3 rounded-xl border border-border cursor-pointer">
                  <input
                    type="checkbox"
                    checked={hasOven}
                    onChange={(e) => setHasOven(e.target.checked)}
                    className="w-4 h-4 accent-secondary"
                  />
                  <span className="text-xs font-semibold">Çalışır durumda fırın mevcut</span>
                </label>
                <label className="flex items-center gap-3 p-3 rounded-xl border border-border cursor-pointer">
                  <input
                    type="checkbox"
                    checked={hasBlender}
                    onChange={(e) => setHasBlender(e.target.checked)}
                    className="w-4 h-4 accent-secondary"
                  />
                  <span className="text-xs font-semibold">Blender / Mutfak robotu mevcut</span>
                </label>
                <label className="flex items-center gap-3 p-3 rounded-xl border border-border cursor-pointer">
                  <input
                    type="checkbox"
                    checked={hasIceMaker}
                    onChange={(e) => setHasIceMaker(e.target.checked)}
                    className="w-4 h-4 accent-secondary"
                  />
                  <span className="text-xs font-semibold">
                    Buzluk / Kokteyl için geniş dondurucu alanı mevcut
                  </span>
                </label>
              </div>

              <div>
                <label className="text-xs font-bold uppercase text-muted-foreground block mb-2">
                  Alerjen & Diyet Bildirimi (Varsa Seçiniz)
                </label>
                <div className="flex flex-wrap gap-2">
                  {ALLERGEN_OPTIONS.map((alg) => {
                    const active = selectedAllergies.includes(alg);
                    return (
                      <button
                        key={alg}
                        type="button"
                        onClick={() => toggleAllergy(alg)}
                        className={`px-3 py-1.5 rounded-full text-xs font-semibold border transition ${
                          active
                            ? "bg-secondary text-secondary-foreground border-secondary"
                            : "border-border text-muted-foreground hover:text-foreground"
                        }`}
                      >
                        {active ? `✓ ${alg}` : alg}
                      </button>
                    );
                  })}
                </div>
              </div>

              <div className="flex justify-between pt-2">
                <Button variant="outline" onClick={() => setStep(1)} className="rounded-xl">
                  ← Geri
                </Button>
                <Button onClick={() => setStep(3)} className="rounded-xl px-6 font-bold">
                  Adım 3: Malzeme Tedarik Modeli →
                </Button>
              </div>
            </div>
          )}

          {/* STEP 3: Ingredient Sourcing Model */}
          {step === 3 && (
            <div className="bg-card border border-border p-6 md:p-8 rounded-2xl shadow-sm space-y-6">
              <div className="flex items-center gap-2.5">
                <ShoppingBag className="w-5 h-5 text-secondary" />
                <h2 className="font-serif text-xl font-bold">
                  Adım 3: Malzeme Tedarik Tercihi
                </h2>
              </div>

              <div className="space-y-3">
                <div
                  onClick={() => setIngredientsIncluded(true)}
                  className={`p-4 rounded-2xl border cursor-pointer transition ${
                    ingredientsIncluded
                      ? "border-secondary bg-secondary/10"
                      : "border-border hover:border-secondary/40"
                  }`}
                >
                  <div className="flex items-center justify-between">
                    <span className="font-bold text-sm">
                      Malzemeleri Şef Temin Etsin (Önerilen)
                    </span>
                    <Badge variant="secondary">Fiyata Dahil</Badge>
                  </div>
                  <p className="text-xs text-muted-foreground mt-1">
                    Şef etkinlik sabahı en taze malzemeleri kendi tedarikçilerinden seçer ve
                    canlı takip ekranında tedarik fişini paylaşır.
                  </p>
                </div>

                <div
                  onClick={() => setIngredientsIncluded(false)}
                  className={`p-4 rounded-2xl border cursor-pointer transition ${
                    !ingredientsIncluded
                      ? "border-secondary bg-secondary/10"
                      : "border-border hover:border-secondary/40"
                  }`}
                >
                  <div className="flex items-center justify-between">
                    <span className="font-bold text-sm">
                      Malzemeleri Ben Alacağım (%20 İndirimli)
                    </span>
                    <Badge variant="outline">-₺{ingredientDiscount.toLocaleString("tr-TR")}</Badge>
                  </div>
                  <p className="text-xs text-muted-foreground mt-1">
                    Şefin hazırladığı reçete listesine göre alışverişi siz yaparsınız, şef yalnızca
                    pişirme ve sunum hizmeti verir.
                  </p>
                </div>
              </div>

              <div>
                <label className="text-xs font-bold uppercase text-muted-foreground block mb-1.5">
                  Şefe Özel Notunuz / Kapı Zili Bilgisi
                </label>
                <Input
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  placeholder="Örn: Yıldönümü kutlaması, tatlı tabağında kutlama yazısı rica ederiz."
                />
              </div>

              <div className="flex justify-between pt-2">
                <Button variant="outline" onClick={() => setStep(2)} className="rounded-xl">
                  ← Geri
                </Button>
                <Button onClick={() => setStep(4)} className="rounded-xl px-6 font-bold">
                  Adım 4: Barmen & Kokteyl Ekle →
                </Button>
              </div>
            </div>
          )}

          {/* STEP 4: Bartender Cross-Sell (Upsell) */}
          {step === 4 && (
            <div className="bg-card border border-border p-6 md:p-8 rounded-2xl shadow-sm space-y-6">
              <div className="flex items-center gap-2.5">
                <Wine className="w-5 h-5 text-secondary" />
                <div>
                  <h2 className="font-serif text-xl font-bold">
                    Adım 4: Yemeğin Yanına Özel Barmen & Kokteyl Barı Ekle (Upsell)
                  </h2>
                  <p className="text-xs text-muted-foreground">
                    İsterseniz gecenize ödüllü bir miksolojist ekleyerek imza kokteyl servisi
                    alabilirsiniz.
                  </p>
                </div>
              </div>

              <div className="space-y-3">
                <div
                  onClick={() => setSelectedBartenderId(null)}
                  className={`p-4 rounded-xl border cursor-pointer text-xs font-semibold transition ${
                    selectedBartenderId === null
                      ? "border-secondary bg-secondary/10 text-foreground"
                      : "border-border text-muted-foreground"
                  }`}
                >
                  Barmen eklemeden yalnızca şef hizmeti ile devam et
                </div>

                {bartenders.map((b) => {
                  const isSelected = selectedBartenderId === b.id;
                  const bMenu = b.menus?.[0];
                  const bPrice = bMenu
                    ? Number(bMenu.price_per_person) * guestCount
                    : Number(b.hourly_rate || 1200) * 3;

                  return (
                    <div
                      key={b.id}
                      onClick={() => setSelectedBartenderId(b.id)}
                      className={`p-4 rounded-2xl border cursor-pointer transition flex items-center justify-between gap-4 ${
                        isSelected
                          ? "border-secondary bg-secondary/10 shadow-xs"
                          : "border-border hover:border-secondary/40"
                      }`}
                    >
                      <div className="flex items-center gap-3">
                        <img
                          src={
                            b.user?.avatar_url ||
                            "https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?auto=format&fit=crop&w=300&q=80"
                          }
                          alt={b.user?.full_name}
                          className="w-14 h-14 rounded-xl object-cover shrink-0"
                        />
                        <div>
                          <div className="font-bold text-sm text-foreground">
                            {b.user?.full_name}
                          </div>
                          <div className="text-xs text-secondary font-medium">{b.title}</div>
                          <div className="text-[11px] text-muted-foreground mt-0.5">
                            Paket: {bMenu?.title || "3 Saatlik İmza Kokteyl & Bar Servisi"}
                          </div>
                        </div>
                      </div>

                      <div className="text-right shrink-0">
                        <div className="font-serif font-bold text-base text-secondary">
                          +₺{bPrice.toLocaleString("tr-TR")}
                        </div>
                        <div className="text-[10px] text-muted-foreground">
                          {guestCount} Kişi Toplam
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>

              <div className="flex justify-between pt-2">
                <Button variant="outline" onClick={() => setStep(3)} className="rounded-xl">
                  ← Geri
                </Button>
                <Button onClick={() => setStep(5)} className="rounded-xl px-6 font-bold">
                  Adım 5: Ödeme & Escrow Onayı →
                </Button>
              </div>
            </div>
          )}

          {/* STEP 5: Final Escrow Checkout Confirmation */}
          {step === 5 && (
            <div className="bg-card border border-border p-6 md:p-8 rounded-2xl shadow-sm space-y-6">
              <div className="flex items-center gap-2.5">
                <ShieldCheck className="w-6 h-6 text-emerald-500" />
                <div>
                  <h2 className="font-serif text-xl font-bold">
                    Adım 5: Güvenli Escrow Ödeme & Ön Provizyon
                  </h2>
                  <p className="text-xs text-muted-foreground">
                    iyzico Pazaryeri güvencesiyle ödemeniz havuzda bloke edilir, etkinlik sonunda
                    onayınızla şefe aktarılır.
                  </p>
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 bg-muted/50 p-4 rounded-2xl border border-border/60 text-xs space-y-1">
                <div>
                  <span className="text-muted-foreground">Tarih & Saat:</span>{" "}
                  <strong className="text-foreground">
                    {eventDate} • {eventTime}
                  </strong>
                </div>
                <div>
                  <span className="text-muted-foreground">Misafir Sayısı:</span>{" "}
                  <strong className="text-foreground">{guestCount} Kişi</strong>
                </div>
                <div>
                  <span className="text-muted-foreground">Mutfak Donanımı:</span>{" "}
                  <strong className="text-foreground capitalize">
                    {stoveType} Ocak, {hasOven ? "Fırın Var" : "Fırın Yok"}
                  </strong>
                </div>
                <div>
                  <span className="text-muted-foreground">Alerjenler:</span>{" "}
                  <strong className="text-foreground">
                    {selectedAllergies.length > 0 ? selectedAllergies.join(", ") : "Yok"}
                  </strong>
                </div>
              </div>

              {/* Mock 3D Secure Card Input */}
              <div className="space-y-3 pt-2">
                <label className="text-xs font-bold uppercase text-muted-foreground block">
                  Kredi / Banka Kartı Bilgileri (iyzico Escrow)
                </label>
                <Input defaultValue="4543 •••• •••• 4821" readOnly className="font-mono text-sm" />
                <div className="grid grid-cols-2 gap-3">
                  <Input defaultValue="10 / 28" readOnly className="font-mono text-sm" />
                  <Input defaultValue="•••" readOnly className="font-mono text-sm" />
                </div>
              </div>

              <div className="flex justify-between items-center pt-2">
                <Button variant="outline" onClick={() => setStep(4)} className="rounded-xl">
                  ← Geri
                </Button>
                <Button
                  disabled={submitting}
                  onClick={handleCompleteEscrowBooking}
                  className="py-6 px-8 rounded-xl font-bold text-sm gap-2 cursor-pointer"
                >
                  {submitting ? (
                    <Loader2 className="w-4 h-4 animate-spin" />
                  ) : (
                    <Sparkles className="w-4 h-4" />
                  )}
                  ₺{totalPrice.toLocaleString("tr-TR")} Escrow İle Öde & Rezerve Et
                </Button>
              </div>
            </div>
          )}
        </div>

        {/* Right Column: Sticky Live Escrow Breakdown */}
        <div className="lg:col-span-5">
          <div className="bg-card border border-border p-6 rounded-3xl shadow-md sticky top-28 space-y-5">
            <h2 className="font-serif text-xl font-bold pb-3 border-b border-border">
              Rezervasyon & Escrow Özeti
            </h2>

            <div className="space-y-3 text-xs md:text-sm">
              <div className="flex justify-between">
                <span className="text-muted-foreground">
                  {isHourly
                    ? `Saatlik Şef Hizmeti (${hoursCount} Saat)`
                    : `${activeMenu?.title || "Tadım Menüsü"} (${guestCount} Kişi)`}
                </span>
                <span className="font-semibold">
                  ₺{baseServiceTotal.toLocaleString("tr-TR")}
                </span>
              </div>

              {!ingredientsIncluded && (
                <div className="flex justify-between text-emerald-600">
                  <span>Malzeme Müşteriden İndirimi (-%20)</span>
                  <span className="font-semibold">
                    -₺{ingredientDiscount.toLocaleString("tr-TR")}
                  </span>
                </div>
              )}

              {selectedBartender && (
                <div className="flex justify-between text-secondary">
                  <span>+ Barmen Upsell ({selectedBartender.user?.full_name})</span>
                  <span className="font-semibold">+₺{addonPrice.toLocaleString("tr-TR")}</span>
                </div>
              )}

              <div className="border-t border-border pt-3 flex justify-between font-bold text-base">
                <span>Toplam Bloke Edilecek Tutar</span>
                <span className="text-secondary">₺{totalPrice.toLocaleString("tr-TR")}</span>
              </div>

              {/* Transparent 10% Commission & 90% Chef Payout Breakdown */}
              <div className="bg-muted/60 p-3.5 rounded-xl border border-border/60 space-y-1.5 text-xs">
                <div className="flex justify-between text-muted-foreground">
                  <span>GastroHost Platform Komisyonu (%10)</span>
                  <span className="font-semibold text-foreground">
                    ₺{platformFee.toLocaleString("tr-TR")}
                  </span>
                </div>
                <div className="flex justify-between text-muted-foreground">
                  <span>Şef / Barmen Net Hakedişi (%90)</span>
                  <span className="font-semibold text-emerald-600">
                    ₺{providerEarnings.toLocaleString("tr-TR")}
                  </span>
                </div>
              </div>
            </div>

            <div className="bg-emerald-500/10 border border-emerald-500/25 p-4 rounded-2xl flex items-start gap-3 text-xs text-muted-foreground">
              <CheckCircle2 className="w-5 h-5 text-emerald-600 shrink-0 mt-0.5" />
              <div>
                <div className="font-bold text-foreground mb-0.5">
                  %100 GastroHost Escrow Garantisi
                </div>
                Ödemeniz etkinlik tamamlanıp siz onay verene kadar havuzda güvende tutulur.
              </div>
            </div>
          </div>
        </div>
      </div>
    </main>
  );
}

export default function BookingPage() {
  return (
    <div className="min-h-screen bg-background text-foreground antialiased pb-24 md:pb-16">
      <Header />
      <React.Suspense
        fallback={
          <div className="pt-36 flex items-center justify-center">
            <Loader2 className="w-8 h-8 animate-spin text-secondary" />
          </div>
        }
      >
        <BookingWizardContent />
      </React.Suspense>
      <MobileBottomNav />
    </div>
  );
}
