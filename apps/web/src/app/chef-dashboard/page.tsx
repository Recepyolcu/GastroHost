"use client";

import * as React from "react";
import Link from "next/link";
import {
  Calendar,
  CheckCircle2,
  MessageSquare,
  Clock,
  Plus,
  Utensils,
  Wallet,
  FileText,
  ShieldCheck,
  Award,
  Loader2,
  RefreshCw,
  ChefHat,
  ArrowRight,
  Power,
} from "lucide-react";
import { Header } from "@/components/home/Header";
import { MobileBottomNav } from "@/components/home/MobileBottomNav";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { supabase } from "@/lib/supabase";
import { useAuth } from "@/lib/auth-context";

interface DashboardProvider {
  id: string;
  user_id: string;
  provider_type: string;
  title: string;
  city_region: string;
  hourly_rate: number;
  is_verified: boolean;
  is_available_now: boolean;
  wallet_balance: number;
  pending_escrow: number;
  completed_bookings_count: number;
  verification_badges?: {
    identity?: boolean;
    criminal_record?: boolean;
    hygiene_cert?: boolean;
    diploma?: boolean;
  };
  user?: {
    full_name: string;
    email: string;
  };
}

interface ProviderBookingItem {
  id: string;
  booking_code: string;
  event_date: string;
  event_time: string;
  guest_count: number;
  total_price: number;
  platform_fee: number;
  provider_earnings: number;
  status: string;
  event_address: string;
  allergies?: string[];
  kitchen_details?: {
    stove_type?: string;
    has_oven?: boolean;
    has_blender?: boolean;
  };
  customer?: {
    full_name: string;
    phone?: string;
  };
  menu?: {
    title: string;
  };
}

interface ProviderMenuItem {
  id: string;
  title: string;
  description: string;
  category: string;
  price_per_person: number;
  min_guests: number;
  max_guests: number;
  ingredients_included: boolean;
  is_active: boolean;
  courses: { type?: string; name: string; description?: string }[];
}

interface AvailabilitySlot {
  id?: string;
  day_of_week: number;
  start_time: string;
  end_time: string;
  is_available: boolean;
}

interface ProviderDocumentRow {
  id: string;
  document_type: string;
  file_url: string;
  status: string;
  rejection_reason?: string | null;
  created_at: string;
}

const DAY_NAMES = ["Pazar", "Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi"];

const STATUS_FLOW: Record<string, { next: string; label: string; badgeText: string }> = {
  pending: {
    next: "accepted",
    label: "Talebi Kabul Et",
    badgeText: "Onay Bekliyor",
  },
  accepted: {
    next: "shopping",
    label: "Alışverişe Başla",
    badgeText: "Onaylandı & Planlandı",
  },
  confirmed: {
    next: "shopping",
    label: "Alışverişe Başla",
    badgeText: "Onaylandı & Planlandı",
  },
  shopping: {
    next: "on_the_way",
    label: "Yola Çıktım",
    badgeText: "Malzeme Tedarikinde",
  },
  on_the_way: {
    next: "in_kitchen",
    label: "Mutfağa Vardım",
    badgeText: "Şef Yolda",
  },
  in_kitchen: {
    next: "completed",
    label: "Servisi Tamamla & Hakedişi Çöz",
    badgeText: "Mutfakta Hazırlıkta",
  },
};

export default function ChefDashboardPage() {
  const { providerProfile } = useAuth();
  const [allProviders, setAllProviders] = React.useState<DashboardProvider[]>([]);
  const [selectedProviderId, setSelectedProviderId] = React.useState<string>("");
  const [activeTab, setActiveTab] = React.useState<"bookings" | "menus" | "calendar" | "wallet">(
    "bookings"
  );
  const [loading, setLoading] = React.useState<boolean>(true);
  const [busyId, setBusyId] = React.useState<string | null>(null);

  const [bookings, setBookings] = React.useState<ProviderBookingItem[]>([]);
  const [menus, setMenus] = React.useState<ProviderMenuItem[]>([]);
  const [availability, setAvailability] = React.useState<AvailabilitySlot[]>([]);
  const [documents, setDocuments] = React.useState<ProviderDocumentRow[]>([]);

  // New Menu Form state
  const [showNewMenuForm, setShowNewMenuForm] = React.useState(false);
  const [newMenuTitle, setNewMenuTitle] = React.useState("");
  const [newMenuCategory, setNewMenuCategory] = React.useState("Fine Dining");
  const [newMenuPrice, setNewMenuPrice] = React.useState(2200);
  const [newMenuDesc, setNewMenuDesc] = React.useState("");
  const [newCourseStarter, setNewCourseStarter] = React.useState("Trüflü Burrata & İncir");
  const [newCourseMain, setNewCourseMain] = React.useState("Ağır Ateşte Dana Kaburga");
  const [newCourseDessert, setNewCourseDessert] = React.useState("Bitter Çikolatalı Sufle");

  // New Document Upload state
  const [newDocType, setNewDocType] = React.useState("hygiene_cert");
  const [newDocUrl, setNewDocUrl] = React.useState(
    "https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&w=800&q=80"
  );

  const loadProvidersList = React.useCallback(async () => {
    const { data } = await supabase
      .from("provider_profiles")
      .select("*, user:profiles(full_name, email)")
      .order("rating_avg", { ascending: false });

    if (data && data.length > 0) {
      const list = data as unknown as DashboardProvider[];
      setAllProviders(list);
      if (!selectedProviderId) {
        const preferred =
          providerProfile?.id ||
          list.find((p) => p.id === "22222222-3333-4444-8555-666666660001")?.id ||
          list[0].id;
        setSelectedProviderId(preferred);
      }
    }
  }, [providerProfile?.id, selectedProviderId]);

  const loadDashboardDetails = React.useCallback(async (provId: string) => {
    if (!provId) return;
    setLoading(true);
    try {
      const [{ data: bData }, { data: mData }, { data: aData }, { data: dData }] =
        await Promise.all([
          supabase
            .from("bookings")
            .select(
              `
              *,
              customer:profiles!bookings_customer_id_fkey(full_name, phone),
              menu:menus!bookings_menu_id_fkey(title)
            `
            )
            .or(`provider_id.eq.${provId},addon_bartender_id.eq.${provId}`)
            .order("created_at", { ascending: false }),
          supabase
            .from("menus")
            .select("*")
            .eq("provider_id", provId)
            .order("created_at", { ascending: false }),
          supabase
            .from("provider_availability")
            .select("*")
            .eq("provider_id", provId)
            .order("day_of_week", { ascending: true }),
          supabase
            .from("provider_documents")
            .select("*")
            .eq("provider_id", provId)
            .order("created_at", { ascending: false }),
        ]);

      setBookings((bData as unknown as ProviderBookingItem[]) || []);
      setMenus((mData as unknown as ProviderMenuItem[]) || []);

      const existingAvail = (aData as unknown as AvailabilitySlot[]) || [];
      const fullWeek: AvailabilitySlot[] = DAY_NAMES.map((_, idx) => {
        const match = existingAvail.find((s) => s.day_of_week === idx);
        return (
          match || {
            day_of_week: idx,
            start_time: "10:00:00",
            end_time: "23:00:00",
            is_available: true,
          }
        );
      });
      setAvailability(fullWeek);
      setDocuments((dData as unknown as ProviderDocumentRow[]) || []);
    } catch (e) {
      console.error("Chef dashboard load error:", e);
    } finally {
      setLoading(false);
    }
  }, []);

  React.useEffect(() => {
    loadProvidersList();
  }, [loadProvidersList]);

  React.useEffect(() => {
    if (selectedProviderId) {
      loadDashboardDetails(selectedProviderId);
    }
  }, [selectedProviderId, loadDashboardDetails]);

  const currentProvider =
    allProviders.find((p) => p.id === selectedProviderId) || allProviders[0];

  const handleToggleAvailableNow = async () => {
    if (!currentProvider) return;
    const nextVal = !currentProvider.is_available_now;
    await supabase
      .from("provider_profiles")
      .update({ is_available_now: nextVal })
      .eq("id", currentProvider.id);
    await loadProvidersList();
  };

  const handleAdvanceBookingStatus = async (booking: ProviderBookingItem, nextStatus: string) => {
    setBusyId(booking.id);
    try {
      if (nextStatus === "completed") {
        await supabase.rpc("release_escrow_payout", { p_booking_id: booking.id });
      } else if (nextStatus === "cancelled") {
        await supabase.rpc("refund_escrow_payment", {
          p_booking_id: booking.id,
          p_reason: "Şef takvim yoğunluğu nedeniyle talebi reddetti.",
        });
      } else {
        await supabase
          .from("bookings")
          .update({
            status: nextStatus,
            accepted_at: nextStatus === "accepted" ? new Date().toISOString() : undefined,
          })
          .eq("id", booking.id);
      }

      await loadProvidersList();
      await loadDashboardDetails(selectedProviderId);
    } finally {
      setBusyId(null);
    }
  };

  const handleCreateMenu = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedProviderId || !newMenuTitle.trim()) return;
    setBusyId("new-menu");
    try {
      await supabase.from("menus").insert({
        provider_id: selectedProviderId,
        title: newMenuTitle.trim(),
        description:
          newMenuDesc.trim() ||
          "Mevsimsel taze malzemelerle hazırlanan özel şef tadım menüsü.",
        category: newMenuCategory,
        pricing_type: "per_person",
        price_per_person: Number(newMenuPrice) || 2000,
        min_guests: 2,
        max_guests: 16,
        ingredients_included: true,
        is_active: true,
        courses: [
          { type: "Başlangıç", name: newCourseStarter },
          { type: "Ana Yemek", name: newCourseMain },
          { type: "Tatlı", name: newCourseDessert },
        ],
      });
      setNewMenuTitle("");
      setNewMenuDesc("");
      setShowNewMenuForm(false);
      await loadDashboardDetails(selectedProviderId);
    } finally {
      setBusyId(null);
    }
  };

  const handleToggleMenuActive = async (menu: ProviderMenuItem) => {
    await supabase
      .from("menus")
      .update({ is_active: !menu.is_active })
      .eq("id", menu.id);
    await loadDashboardDetails(selectedProviderId);
  };

  const handleToggleDayAvailability = async (slot: AvailabilitySlot) => {
    if (!selectedProviderId) return;
    const nextAvail = !slot.is_available;
    if (slot.id) {
      await supabase
        .from("provider_availability")
        .update({ is_available: nextAvail })
        .eq("id", slot.id);
    } else {
      await supabase.from("provider_availability").insert({
        provider_id: selectedProviderId,
        day_of_week: slot.day_of_week,
        start_time: slot.start_time,
        end_time: slot.end_time,
        is_available: nextAvail,
      });
    }
    await loadDashboardDetails(selectedProviderId);
  };

  const handleUploadDocument = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedProviderId || !newDocUrl.trim()) return;
    setBusyId("upload-doc");
    try {
      await supabase.from("provider_documents").insert({
        provider_id: selectedProviderId,
        document_type: newDocType,
        file_url: newDocUrl.trim(),
        status: "pending",
      });
      await loadDashboardDetails(selectedProviderId);
    } finally {
      setBusyId(null);
    }
  };

  return (
    <div className="min-h-screen bg-background text-foreground antialiased pb-24 md:pb-16">
      <Header />

      <main className="pt-24 md:pt-28 px-6 md:px-12 max-w-7xl mx-auto w-full space-y-8">
        {/* Top Bar & Provider Selector */}
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4 border-b border-border pb-6">
          <div>
            <div className="flex items-center gap-2.5">
              <ChefHat className="w-7 h-7 text-secondary" />
              <h1 className="font-serif text-3xl md:text-4xl font-bold">
                Şef & Barmen Yönetim Paneli
              </h1>
            </div>
            <p className="text-sm text-muted-foreground mt-1">
              Rezervasyon durumlarını ilerletin, menülerinizi ve müsaitlik takviminizi yönetin (%90 Net Hakediş).
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            {/* Active Provider Selector for seamless testing */}
            <select
              value={selectedProviderId}
              onChange={(e) => setSelectedProviderId(e.target.value)}
              className="bg-card border border-border rounded-xl px-3.5 py-2 text-xs font-bold text-foreground focus:outline-none focus:border-secondary"
            >
              {allProviders.map((p) => (
                <option key={p.id} value={p.id}>
                  {p.user?.full_name} ({p.provider_type === "bartender" ? "Barmen" : "Özel Şef"})
                </option>
              ))}
            </select>

            {currentProvider && (
              <button
                onClick={handleToggleAvailableNow}
                className={`flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-bold border transition cursor-pointer ${
                  currentProvider.is_available_now
                    ? "bg-emerald-500/15 border-emerald-500/40 text-emerald-600"
                    : "bg-muted border-border text-muted-foreground"
                }`}
              >
                <Power className="w-3.5 h-3.5" />
                {currentProvider.is_available_now ? "Rezervasyona Açık" : "Meşgul / Kapalı"}
              </button>
            )}

            <Button
              variant="outline"
              size="sm"
              onClick={() => loadDashboardDetails(selectedProviderId)}
              className="rounded-xl gap-1.5 text-xs"
            >
              <RefreshCw className={`w-3.5 h-3.5 ${loading ? "animate-spin" : ""}`} /> Yenile
            </Button>
          </div>
        </div>

        {/* Financial & Operational KPI Row */}
        {currentProvider && (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
            <div className="bg-card border border-border p-5 rounded-2xl shadow-xs">
              <div className="text-xs uppercase text-muted-foreground font-bold">
                Çekilebilir Net Cüzdan (%90)
              </div>
              <div className="font-serif text-3xl font-bold text-emerald-600 mt-2">
                ₺{Number(currentProvider.wallet_balance || 0).toLocaleString("tr-TR", {
                  minimumFractionDigits: 2,
                })}
              </div>
              <p className="text-[11px] text-muted-foreground mt-1">
                IBAN hesabınıza aktarıma hazır bakiye
              </p>
            </div>

            <div className="bg-card border border-border p-5 rounded-2xl shadow-xs">
              <div className="text-xs uppercase text-muted-foreground font-bold">
                Escrow Havuzunda Bekleyen
              </div>
              <div className="font-serif text-3xl font-bold text-secondary mt-2">
                ₺{Number(currentProvider.pending_escrow || 0).toLocaleString("tr-TR", {
                  minimumFractionDigits: 2,
                })}
              </div>
              <p className="text-[11px] text-muted-foreground mt-1">
                Aktif etkinlikler tamamlandığında cüzdana geçer
              </p>
            </div>

            <div className="bg-card border border-border p-5 rounded-2xl shadow-xs">
              <div className="text-xs uppercase text-muted-foreground font-bold">
                Aktif & Gelen Talepler
              </div>
              <div className="font-serif text-3xl font-bold mt-2">{bookings.length} Rezervasyon</div>
              <p className="text-[11px] text-muted-foreground mt-1">
                Canlı operasyon takibindeki etkinlikler
              </p>
            </div>

            <div className="bg-card border border-border p-5 rounded-2xl shadow-xs">
              <div className="text-xs uppercase text-muted-foreground font-bold">
                Hibrit Güven Rozetleri
              </div>
              <div className="flex flex-wrap gap-1.5 mt-2.5">
                {currentProvider.is_verified && (
                  <Badge variant="secondary" className="text-[10px] gap-1">
                    <ShieldCheck className="w-3 h-3" /> Onaylı
                  </Badge>
                )}
                {currentProvider.verification_badges?.hygiene_cert && (
                  <Badge variant="outline" className="text-[10px] gap-1">
                    <Award className="w-3 h-3 text-secondary" /> Hijyen
                  </Badge>
                )}
                {currentProvider.verification_badges?.diploma && (
                  <Badge variant="outline" className="text-[10px] gap-1">
                    <Award className="w-3 h-3 text-secondary" /> Diploma
                  </Badge>
                )}
              </div>
              <p className="text-[11px] text-muted-foreground mt-2">
                {menus.length} Aktif Tadım Menüsü
              </p>
            </div>
          </div>
        )}

        {/* Navigation Tabs */}
        <div className="flex flex-wrap items-center gap-2 bg-muted/60 p-1.5 rounded-2xl border border-border/60 w-fit">
          {[
            { id: "bookings", label: `Rezervasyon & Operasyon (${bookings.length})`, icon: Clock },
            { id: "menus", label: `Menülerim & Paketler (${menus.length})`, icon: Utensils },
            { id: "calendar", label: "Haftalık Müsaitlik Takvimi", icon: Calendar },
            { id: "wallet", label: `Cüzdan & Belgelerim (${documents.length})`, icon: Wallet },
          ].map((t) => {
            const Icon = t.icon;
            return (
              <button
                key={t.id}
                onClick={() => setActiveTab(t.id as typeof activeTab)}
                className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition cursor-pointer ${
                  activeTab === t.id
                    ? "bg-primary text-primary-foreground shadow-xs"
                    : "text-muted-foreground hover:text-foreground"
                }`}
              >
                <Icon className="w-4 h-4" />
                <span>{t.label}</span>
              </button>
            );
          })}
        </div>

        {/* TAB 1: Bookings & Live Lifecycle Operations */}
        {activeTab === "bookings" && (
          <div className="space-y-4">
            {loading ? (
              <div className="py-16 flex justify-center">
                <Loader2 className="w-8 h-8 animate-spin text-secondary" />
              </div>
            ) : bookings.length === 0 ? (
              <div className="p-12 text-center bg-card border border-border rounded-2xl">
                <p className="text-sm text-muted-foreground">
                  Bu sağlayıcıya ait henüz bir rezervasyon kaydı bulunmuyor.
                </p>
              </div>
            ) : (
              bookings.map((b) => {
                const flow = STATUS_FLOW[b.status];
                const isBusy = busyId === b.id;

                return (
                  <div
                    key={b.id}
                    className="bg-card border border-border p-6 rounded-2xl shadow-xs flex flex-col lg:flex-row justify-between items-start lg:items-center gap-6"
                  >
                    <div className="space-y-2.5">
                      <div className="flex flex-wrap items-center gap-2.5">
                        <span className="font-mono text-xs font-bold px-2.5 py-1 rounded-lg bg-muted">
                          {b.booking_code}
                        </span>
                        <span className="font-serif font-bold text-lg text-foreground">
                          {b.customer?.full_name || "Ev Sahibi Müşteri"}
                        </span>
                        <Badge variant="secondary">
                          Net Hakediş: ₺{Number(b.provider_earnings || 0).toLocaleString("tr-TR")} (%90)
                        </Badge>
                        <Badge variant="outline" className="capitalize">
                          {flow?.badgeText || (b.status === "completed" ? "Tamamlandı" : "İptal Edildi")}
                        </Badge>
                      </div>

                      <p className="text-sm font-medium text-foreground">
                        {b.menu?.title || "Özel Şef / Miksoloji Hizmeti"} • {b.guest_count} Misafir
                      </p>

                      <div className="flex flex-wrap items-center gap-4 text-xs text-muted-foreground">
                        <span className="flex items-center gap-1">
                          <Calendar className="w-3.5 h-3.5 text-secondary" /> {b.event_date} •{" "}
                          {b.event_time?.slice(0, 5)}
                        </span>
                        <span>📍 {b.event_address}</span>
                      </div>

                      {/* Kitchen & Allergen Pills */}
                      <div className="flex flex-wrap gap-2 pt-1">
                        {b.kitchen_details?.stove_type && (
                          <Badge variant="outline" className="text-[11px]">
                            Ocak: {b.kitchen_details.stove_type}
                          </Badge>
                        )}
                        {b.kitchen_details?.has_oven && (
                          <Badge variant="outline" className="text-[11px]">
                            ✓ Fırın Var
                          </Badge>
                        )}
                        {Array.isArray(b.allergies) &&
                          b.allergies.map((alg) => (
                            <Badge
                              key={alg}
                              variant="secondary"
                              className="text-[11px] bg-rose-500/10 text-rose-600"
                            >
                              ⚠️ {alg}
                            </Badge>
                          ))}
                      </div>
                    </div>

                    {/* Action Buttons */}
                    <div className="flex flex-wrap items-center gap-2.5 w-full lg:w-auto justify-end">
                      <Link href={`/chat?bookingId=${b.id}`}>
                        <Button variant="outline" size="sm" className="rounded-xl gap-1.5 text-xs">
                          <MessageSquare className="w-3.5 h-3.5 text-secondary" /> Sohbet
                        </Button>
                      </Link>
                      <Link href={`/tracker?bookingId=${b.id}`}>
                        <Button variant="outline" size="sm" className="rounded-xl gap-1.5 text-xs">
                          Canlı Takip
                        </Button>
                      </Link>

                      {b.status === "pending" && (
                        <Button
                          variant="outline"
                          size="sm"
                          disabled={isBusy}
                          onClick={() => handleAdvanceBookingStatus(b, "cancelled")}
                          className="rounded-xl text-xs text-destructive border-destructive/30"
                        >
                          Reddet
                        </Button>
                      )}

                      {flow && (
                        <Button
                          size="sm"
                          disabled={isBusy}
                          onClick={() => handleAdvanceBookingStatus(b, flow.next)}
                          className="rounded-xl text-xs font-bold gap-1.5 cursor-pointer"
                        >
                          {isBusy ? (
                            <Loader2 className="w-3.5 h-3.5 animate-spin" />
                          ) : (
                            <>
                              <span>{flow.label}</span>
                              <ArrowRight className="w-3.5 h-3.5" />
                            </>
                          )}
                        </Button>
                      )}

                      {b.status === "completed" && (
                        <span className="inline-flex items-center gap-1 text-xs font-bold text-emerald-600 px-3 py-1.5 rounded-xl bg-emerald-500/10">
                          <CheckCircle2 className="w-4 h-4" /> Hakediş Cüzdana Aktarıldı
                        </span>
                      )}
                    </div>
                  </div>
                );
              })
            )}
          </div>
        )}

        {/* TAB 2: Menus CRUD Management */}
        {activeTab === "menus" && (
          <div className="space-y-6">
            <div className="flex items-center justify-between">
              <h2 className="font-serif text-2xl font-bold">Tadım Menülerim & Kokteyl Paketlerim</h2>
              <Button
                onClick={() => setShowNewMenuForm((prev) => !prev)}
                className="rounded-xl gap-1.5 text-xs font-bold cursor-pointer"
              >
                <Plus className="w-4 h-4" /> Yeni Menü / Paket Ekle
              </Button>
            </div>

            {showNewMenuForm && (
              <form
                onSubmit={handleCreateMenu}
                className="bg-card border border-secondary/40 p-6 rounded-2xl shadow-md space-y-4"
              >
                <h3 className="font-serif text-lg font-bold">Yeni Tadım Menüsü Oluştur</h3>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div>
                    <label className="text-xs font-bold uppercase text-muted-foreground block mb-1">
                      Menü Başlığı
                    </label>
                    <Input
                      required
                      value={newMenuTitle}
                      onChange={(e) => setNewMenuTitle(e.target.value)}
                      placeholder="Örn: Ege Denizi & Trüf Senfonisi"
                    />
                  </div>
                  <div>
                    <label className="text-xs font-bold uppercase text-muted-foreground block mb-1">
                      Kategori
                    </label>
                    <Input
                      value={newMenuCategory}
                      onChange={(e) => setNewMenuCategory(e.target.value)}
                      placeholder="Fine Dining / İtalyan / Kokteyl"
                    />
                  </div>
                  <div>
                    <label className="text-xs font-bold uppercase text-muted-foreground block mb-1">
                      Kişi Başı Fiyat (₺)
                    </label>
                    <Input
                      type="number"
                      value={newMenuPrice}
                      onChange={(e) => setNewMenuPrice(Number(e.target.value))}
                    />
                  </div>
                </div>

                <div>
                  <label className="text-xs font-bold uppercase text-muted-foreground block mb-1">
                    Menü Açıklaması
                  </label>
                  <Input
                    value={newMenuDesc}
                    onChange={(e) => setNewMenuDesc(e.target.value)}
                    placeholder="Menü hikayesi ve öne çıkan teknikler..."
                  />
                </div>

                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div>
                    <label className="text-xs font-bold uppercase text-muted-foreground block mb-1">
                      1. Aşama (Başlangıç)
                    </label>
                    <Input
                      value={newCourseStarter}
                      onChange={(e) => setNewCourseStarter(e.target.value)}
                    />
                  </div>
                  <div>
                    <label className="text-xs font-bold uppercase text-muted-foreground block mb-1">
                      2. Aşama (Ana Yemek)
                    </label>
                    <Input
                      value={newCourseMain}
                      onChange={(e) => setNewCourseMain(e.target.value)}
                    />
                  </div>
                  <div>
                    <label className="text-xs font-bold uppercase text-muted-foreground block mb-1">
                      3. Aşama (Tatlı / Final)
                    </label>
                    <Input
                      value={newCourseDessert}
                      onChange={(e) => setNewCourseDessert(e.target.value)}
                    />
                  </div>
                </div>

                <div className="flex justify-end gap-2">
                  <Button
                    type="button"
                    variant="outline"
                    onClick={() => setShowNewMenuForm(false)}
                    className="rounded-xl text-xs"
                  >
                    Vazgeç
                  </Button>
                  <Button
                    type="submit"
                    disabled={busyId === "new-menu"}
                    className="rounded-xl text-xs font-bold"
                  >
                    Menüyü Kaydet & Yayınla
                  </Button>
                </div>
              </form>
            )}

            <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
              {menus.map((m) => (
                <div
                  key={m.id}
                  className="bg-card border border-border p-6 rounded-2xl flex flex-col justify-between gap-4"
                >
                  <div className="space-y-2">
                    <div className="flex items-start justify-between gap-2">
                      <div>
                        <h3 className="font-serif font-bold text-lg">{m.title}</h3>
                        <Badge variant="outline" className="text-[10px] mt-1">
                          {m.category}
                        </Badge>
                      </div>
                      <div className="font-serif text-xl font-bold text-secondary">
                        ₺{Number(m.price_per_person).toLocaleString("tr-TR")}/kişi
                      </div>
                    </div>
                    <p className="text-xs text-muted-foreground">{m.description}</p>
                  </div>

                  <div className="flex items-center justify-between pt-3 border-t border-border">
                    <span
                      className={`text-xs font-bold ${
                        m.is_active ? "text-emerald-600" : "text-muted-foreground"
                      }`}
                    >
                      {m.is_active ? "● Yayında (Aktif)" : "○ Pasif"}
                    </span>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => handleToggleMenuActive(m)}
                      className="rounded-xl text-xs"
                    >
                      {m.is_active ? "Pasife Al" : "Yayına Al"}
                    </Button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* TAB 3: Weekly Availability Calendar */}
        {activeTab === "calendar" && (
          <div className="bg-card border border-border p-6 md:p-8 rounded-2xl space-y-5">
            <div>
              <h2 className="font-serif text-2xl font-bold">Haftalık Çalışma Saatleri & Müsaitlik</h2>
              <p className="text-xs text-muted-foreground mt-1">
                Hangi günlerde rezervasyon kabul ettiğinizi tek tıkla güncelleyin.
              </p>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-7 gap-3">
              {availability.map((slot) => (
                <div
                  key={slot.day_of_week}
                  className={`p-4 rounded-2xl border flex flex-col justify-between gap-4 ${
                    slot.is_available
                      ? "border-secondary/50 bg-secondary/5"
                      : "border-border bg-muted/30 opacity-65"
                  }`}
                >
                  <div>
                    <div className="font-bold text-sm">{DAY_NAMES[slot.day_of_week]}</div>
                    <div className="text-xs text-muted-foreground mt-1">
                      {slot.is_available
                        ? `${slot.start_time.slice(0, 5)} - ${slot.end_time.slice(0, 5)}`
                        : "Rezervasyona Kapalı"}
                    </div>
                  </div>
                  <Button
                    size="sm"
                    variant={slot.is_available ? "secondary" : "outline"}
                    onClick={() => handleToggleDayAvailability(slot)}
                    className="w-full rounded-xl text-xs font-bold cursor-pointer"
                  >
                    {slot.is_available ? "Açık ✓" : "Kapalı"}
                  </Button>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* TAB 4: Wallet & Hybrid Trust Documents */}
        {activeTab === "wallet" && (
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
            <div className="lg:col-span-7 bg-card border border-border p-6 rounded-2xl space-y-4">
              <h2 className="font-serif text-xl font-bold flex items-center gap-2">
                <FileText className="w-5 h-5 text-secondary" /> Yüklenen Güvenlik & Rozet Belgelerim
              </h2>
              <div className="space-y-2.5">
                {documents.map((doc) => (
                  <div
                    key={doc.id}
                    className="p-3.5 rounded-xl border border-border flex items-center justify-between text-xs"
                  >
                    <div>
                      <div className="font-bold">
                        {doc.document_type === "hygiene_cert"
                          ? "Hijyen Eğitimi Sertifikası"
                          : doc.document_type === "diploma"
                          ? "Gastronomi / Aşçılık Diploması"
                          : doc.document_type === "identity"
                          ? "T.C. Kimlik / Pasaport"
                          : doc.document_type === "criminal_record"
                          ? "Adli Sicil Kaydı"
                          : doc.document_type}
                      </div>
                      <div className="text-muted-foreground text-[11px]">
                        {new Date(doc.created_at).toLocaleDateString("tr-TR")}
                      </div>
                    </div>
                    <Badge
                      variant={doc.status === "approved" ? "secondary" : "outline"}
                      className="capitalize"
                    >
                      {doc.status === "approved"
                        ? "Onaylandı ✓"
                        : doc.status === "pending"
                        ? "Admin İncelemesinde"
                        : "Reddedildi"}
                    </Badge>
                  </div>
                ))}
              </div>
            </div>

            <div className="lg:col-span-5 bg-card border border-border p-6 rounded-2xl space-y-4">
              <h2 className="font-serif text-xl font-bold">Yeni Sertifika / Belge Yükle</h2>
              <p className="text-xs text-muted-foreground">
                Hijyen Eğitimi Sertifikası veya Gastronomi Diploması yükleyerek profilinize rozet
                ekletebilirsiniz.
              </p>
              <form onSubmit={handleUploadDocument} className="space-y-3">
                <div>
                  <label className="text-xs font-bold uppercase text-muted-foreground block mb-1">
                    Belge Türü
                  </label>
                  <select
                    value={newDocType}
                    onChange={(e) => setNewDocType(e.target.value)}
                    className="w-full bg-background border border-border rounded-xl p-2.5 text-xs font-semibold"
                  >
                    <option value="hygiene_cert">Hijyen Eğitimi Sertifikası (+Rozet)</option>
                    <option value="diploma">Gastronomi / Aşçılık Diploması (+Rozet)</option>
                    <option value="identity">T.C. Kimlik / Pasaport (Zorunlu)</option>
                    <option value="criminal_record">Adli Sicil Kaydı (Zorunlu)</option>
                  </select>
                </div>
                <div>
                  <label className="text-xs font-bold uppercase text-muted-foreground block mb-1">
                    Belge Görsel / PDF Bağlantısı
                  </label>
                  <Input
                    value={newDocUrl}
                    onChange={(e) => setNewDocUrl(e.target.value)}
                    placeholder="https://..."
                  />
                </div>
                <Button
                  type="submit"
                  disabled={busyId === "upload-doc"}
                  className="w-full rounded-xl text-xs font-bold py-5"
                >
                  Admin Onayına Gönder
                </Button>
              </form>
            </div>
          </div>
        )}
      </main>

      <MobileBottomNav />
    </div>
  );
}
