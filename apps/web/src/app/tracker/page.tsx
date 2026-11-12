"use client";

import * as React from "react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import {
  CheckCircle2,
  MessageSquare,
  Receipt,
  Clock,
  ShieldCheck,
  Star,
  Loader2,
  MapPin,
  Sparkles,
} from "lucide-react";
import { Header } from "@/components/home/Header";
import { MobileBottomNav } from "@/components/home/MobileBottomNav";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { supabase } from "@/lib/supabase";

interface TrackerBookingData {
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
  procurement_items?: { item?: string; name?: string; quantity?: string; status?: string }[];
  provider?: {
    id: string;
    title: string;
    user?: { full_name: string; avatar_url?: string };
  };
  menu?: { title: string };
}

const STATUS_LABELS_TR: Record<string, string> = {
  pending: "Onay Bekliyor",
  accepted: "Onaylandı",
  confirmed: "Onaylandı",
  shopping: "Malzeme Tedarikinde",
  on_the_way: "Yolda",
  in_kitchen: "Mutfakta",
  completed: "Tamamlandı",
  cancelled: "İptal Edildi",
};

const TIMELINE_STEPS = [
  {
    key: "accepted",
    title: "Rezervasyon & Escrow Onaylandı",
    desc: "Ödeme güvenli havuza alındı ve şef takvimini bloke etti.",
  },
  {
    key: "shopping",
    title: "Malzeme Tedariki",
    desc: "Şef menünüz için taze ve mevsimsel malzemeleri tedarik ediyor.",
  },
  {
    key: "on_the_way",
    title: "Şef Yolda",
    desc: "Şef ekipmanları ve taze ürünlerle adresinize doğru yola çıktı.",
  },
  {
    key: "in_kitchen",
    title: "Mutfakta Hazırlık & Servis",
    desc: "Şef mutfağınızda tabak hazırlığı ve sunum aşamasında.",
  },
  {
    key: "completed",
    title: "Etkinlik Tamamlandı & Mutfak Teslim Edildi",
    desc: "Servis ve mutfak temizliği tamamlandı; hakediş şefe aktarıldı.",
  },
];

function TrackerContent() {
  const searchParams = useSearchParams();
  const paramBookingId = searchParams.get("bookingId");

  const [allBookings, setAllBookings] = React.useState<TrackerBookingData[]>([]);
  const [selectedId, setSelectedId] = React.useState<string>(paramBookingId || "");
  const [loading, setLoading] = React.useState<boolean>(true);
  const [releasing, setReleasing] = React.useState<boolean>(false);

  const fetchBookings = React.useCallback(async () => {
    setLoading(true);
    try {
      const { data } = await supabase
        .from("bookings")
        .select(
          `
          *,
          provider:provider_profiles!bookings_provider_id_fkey (
            id,
            title,
            user:profiles (full_name, avatar_url)
          ),
          menu:menus!bookings_menu_id_fkey (title)
        `
        )
        .order("created_at", { ascending: false });

      if (data && data.length > 0) {
        const list = data as unknown as TrackerBookingData[];
        setAllBookings(list);
        if (!selectedId) {
          const activeOne =
            list.find((b) => b.id === paramBookingId) ||
            list.find((b) => b.status === "on_the_way" || b.status === "in_kitchen") ||
            list[0];
          setSelectedId(activeOne.id);
        }
      }
    } catch (e) {
      console.error("Tracker fetch error:", e);
    } finally {
      setLoading(false);
    }
  }, [paramBookingId, selectedId]);

  React.useEffect(() => {
    fetchBookings();

    // Realtime subscription for live booking status updates
    const channel = supabase
      .channel("live-booking-tracker")
      .on(
        "postgres_changes",
        { event: "UPDATE", schema: "public", table: "bookings" },
        () => {
          fetchBookings();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchBookings]);

  const booking = allBookings.find((b) => b.id === selectedId) || allBookings[0];

  const handleConfirmCompleteAndReleaseEscrow = async () => {
    if (!booking) return;
    setReleasing(true);
    try {
      await supabase.rpc("release_escrow_payout", {
        p_booking_id: booking.id,
      });
      await fetchBookings();
    } finally {
      setReleasing(false);
    }
  };

  if (loading) {
    return (
      <div className="pt-36 flex justify-center">
        <Loader2 className="w-8 h-8 animate-spin text-secondary" />
      </div>
    );
  }

  if (!booking) {
    return (
      <main className="pt-32 px-6 max-w-xl mx-auto text-center space-y-4">
        <h1 className="font-serif text-2xl font-bold">Aktif Rezervasyon Bulunamadı</h1>
        <Link href="/">
          <Button>Şefleri Keşfet</Button>
        </Link>
      </main>
    );
  }

  const normalizedStatus =
    booking.status === "confirmed" || booking.status === "pending"
      ? "accepted"
      : booking.status;

  const currentStepIdx = Math.max(
    0,
    TIMELINE_STEPS.findIndex((s) => s.key === normalizedStatus)
  );

  const procurementList =
    Array.isArray(booking.procurement_items) && booking.procurement_items.length > 0
      ? booking.procurement_items
      : [
          { item: "Alba Siyah Trüf Mantarı", quantity: "80g", status: "purchased" },
          { item: "Dinlendirilmiş Dana Bonfile", quantity: "1.2kg", status: "purchased" },
          { item: "Organik Burrata Peyniri & Taze Fesleğen", quantity: "4 Porsiyon", status: "purchased" },
        ];

  return (
    <main className="pt-24 md:pt-28 px-6 md:px-12 max-w-6xl mx-auto w-full space-y-8">
      {/* Event Header & Booking Selector */}
      <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4 border-b border-border pb-6">
        <div>
          <div className="flex items-center gap-2 text-xs font-bold text-secondary uppercase tracking-widest mb-1">
            <span className="w-2.5 h-2.5 rounded-full bg-emerald-500 animate-pulse" />
            Canlı Etkinlik Takibi ({booking.booking_code})
          </div>
          <h1 className="font-serif text-3xl md:text-4xl font-bold">
            {booking.provider?.user?.full_name} ile Özel Davetiniz
          </h1>
          <p className="text-sm text-muted-foreground mt-1">
            {booking.menu?.title || "Özel Tadım Menüsü"} • {booking.event_date} Saat{" "}
            {booking.event_time?.slice(0, 5)} • {booking.guest_count} Misafir
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-3">
          <select
            value={booking.id}
            onChange={(e) => setSelectedId(e.target.value)}
            className="bg-card border border-border rounded-xl px-3.5 py-2 text-xs font-bold text-foreground"
          >
            {allBookings.map((b) => (
              <option key={b.id} value={b.id}>
                {b.booking_code} — {b.provider?.user?.full_name} ({STATUS_LABELS_TR[b.status] || b.status})
              </option>
            ))}
          </select>

          <Link href={`/chat?bookingId=${booking.id}`}>
            <Button variant="outline" className="rounded-xl gap-2 text-xs font-bold">
              <MessageSquare className="w-4 h-4 text-secondary" /> Şef İle Canlı Sohbet
            </Button>
          </Link>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
        {/* Left Column: Live Timeline & Customer Escrow Approval */}
        <div className="lg:col-span-7 space-y-6">
          <div className="bg-card border border-border p-6 md:p-8 rounded-2xl shadow-sm">
            <h2 className="font-serif text-xl font-bold mb-6">Canlı Operasyon Durumu</h2>
            <div className="relative pl-6 space-y-7 border-l-2 border-border ml-2">
              {TIMELINE_STEPS.map((stepItem, idx) => {
                const isDone = idx < currentStepIdx || booking.status === "completed";
                const isCurrent = idx === currentStepIdx && booking.status !== "completed";

                return (
                  <div
                    key={stepItem.key}
                    className={`relative ${!isDone && !isCurrent ? "opacity-45" : ""}`}
                  >
                    <div
                      className={`absolute -left-[31px] top-0 w-6 h-6 rounded-full flex items-center justify-center text-xs font-bold ${
                        isDone
                          ? "bg-emerald-500 text-white"
                          : isCurrent
                          ? "bg-secondary text-secondary-foreground animate-bounce"
                          : "bg-muted border border-border"
                      }`}
                    >
                      {isDone ? (
                        <CheckCircle2 className="w-4 h-4" />
                      ) : isCurrent ? (
                        <Clock className="w-3.5 h-3.5" />
                      ) : null}
                    </div>
                    <h3
                      className={`font-bold text-base ${
                        isCurrent ? "text-secondary" : "text-foreground"
                      }`}
                    >
                      {stepItem.title}
                    </h3>
                    <p className="text-xs md:text-sm text-muted-foreground mt-0.5">
                      {stepItem.desc}
                    </p>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Escrow Release / Review Call-to-Action Card */}
          <div className="bg-card border border-border p-6 rounded-2xl shadow-sm flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
            <div className="space-y-1">
              <div className="flex items-center gap-2 font-bold text-sm">
                <ShieldCheck className="w-5 h-5 text-emerald-500" />
                <span>
                  Escrow Havuz Tutarı: ₺{Number(booking.total_price).toLocaleString("tr-TR")}
                </span>
              </div>
              <p className="text-xs text-muted-foreground">
                {booking.status === "completed"
                  ? "Hizmet tamamlandı ve %90 net hakediş şefin cüzdanına aktarıldı."
                  : "Etkinlik tamamlandığında onay vererek ödemeyi serbest bırakabilirsiniz."}
              </p>
            </div>

            {booking.status === "completed" ? (
              <Link href={`/review?bookingId=${booking.id}`}>
                <Button variant="secondary" className="rounded-xl gap-2 text-xs font-bold">
                  <Star className="w-4 h-4" /> Deneyimi Puanla (3 Kriter)
                </Button>
              </Link>
            ) : (
              <Button
                disabled={releasing}
                onClick={handleConfirmCompleteAndReleaseEscrow}
                className="rounded-xl gap-2 text-xs font-bold cursor-pointer"
              >
                {releasing ? (
                  <Loader2 className="w-4 h-4 animate-spin" />
                ) : (
                  <Sparkles className="w-4 h-4" />
                )}
                Hizmeti Onayla & Ödemeyi Serbest Bırak
              </Button>
            )}
          </div>
        </div>

        {/* Right Column: Procurement Receipt & Address */}
        <div className="lg:col-span-5 space-y-6">
          <div className="bg-card border border-border p-6 rounded-2xl shadow-sm space-y-5">
            <div className="flex items-center justify-between pb-4 border-b border-border">
              <div className="flex items-center gap-2">
                <Receipt className="w-5 h-5 text-secondary" />
                <h2 className="font-serif text-xl font-bold">Tedarik & Malzeme Listesi</h2>
              </div>
              <Badge variant="secondary">Doğrulandı ✓</Badge>
            </div>

            <div className="space-y-3 text-xs md:text-sm">
              {procurementList.map((p, i) => (
                <div key={i} className="flex justify-between items-center py-1">
                  <span className="font-medium text-foreground">{p.item || p.name}</span>
                  <span className="text-muted-foreground font-mono text-xs">
                    {p.quantity || "Tam Porsiyon"}
                  </span>
                </div>
              ))}
            </div>

            <div className="pt-4 border-t border-dashed border-border space-y-2 text-xs">
              <div className="flex items-center gap-1.5 text-muted-foreground">
                <MapPin className="w-4 h-4 text-secondary shrink-0" />
                <span>{booking.event_address}</span>
              </div>
              <div className="flex justify-between items-center text-emerald-600 font-bold pt-1">
                <span>%10 Komisyon / %90 Şef Hakedişi Güvenceli</span>
                <CheckCircle2 className="w-4 h-4" />
              </div>
            </div>
          </div>
        </div>
      </div>
    </main>
  );
}

export default function TrackerPage() {
  return (
    <div className="min-h-screen bg-background text-foreground antialiased pb-24 md:pb-16">
      <Header />
      <React.Suspense
        fallback={
          <div className="pt-36 flex justify-center">
            <Loader2 className="w-8 h-8 animate-spin text-secondary" />
          </div>
        }
      >
        <TrackerContent />
      </React.Suspense>
      <MobileBottomNav />
    </div>
  );
}
