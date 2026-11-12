"use client";

import * as React from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { ArrowLeft, Star, CheckCircle2, Loader2, AlertCircle } from "lucide-react";
import { Header } from "@/components/home/Header";
import { MobileBottomNav } from "@/components/home/MobileBottomNav";
import { Button } from "@/components/ui/button";
import { supabase } from "@/lib/supabase";
import { useAuth } from "@/lib/auth-context";

interface ReviewableBooking {
  id: string;
  booking_code: string;
  customer_id: string;
  provider_id: string;
  provider?: {
    id: string;
    user?: { full_name: string };
  };
  menu?: { title: string };
}

function StarRow({
  label,
  subtitle,
  value,
  onChange,
}: {
  label: string;
  subtitle: string;
  value: number;
  onChange: (v: number) => void;
}) {
  return (
    <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 p-4 rounded-2xl bg-muted/40 border border-border/60">
      <div>
        <div className="font-bold text-sm text-foreground">{label}</div>
        <div className="text-xs text-muted-foreground">{subtitle}</div>
      </div>
      <div className="flex items-center gap-1.5">
        {[1, 2, 3, 4, 5].map((star) => (
          <button
            key={star}
            type="button"
            onClick={() => onChange(star)}
            className="p-1 transition-transform hover:scale-110 cursor-pointer"
          >
            <Star
              className={`w-6 h-6 ${
                star <= value
                  ? "fill-secondary text-secondary"
                  : "text-muted-foreground/30"
              }`}
            />
          </button>
        ))}
      </div>
    </div>
  );
}

function ReviewContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const paramBookingId = searchParams.get("bookingId");
  const { userProfile } = useAuth();

  const [bookings, setBookings] = React.useState<ReviewableBooking[]>([]);
  const [selectedBookingId, setSelectedBookingId] = React.useState<string>(paramBookingId || "");
  const [ratingFood, setRatingFood] = React.useState<number>(5);
  const [ratingHygiene, setRatingHygiene] = React.useState<number>(5);
  const [ratingPresentation, setRatingPresentation] = React.useState<number>(5);
  const [comment, setComment] = React.useState<string>("");
  const [submitting, setSubmitting] = React.useState<boolean>(false);
  const [submitted, setSubmitted] = React.useState<boolean>(false);
  const [errorMsg, setErrorMsg] = React.useState<string | null>(null);

  React.useEffect(() => {
    const loadBookings = async () => {
      const { data } = await supabase
        .from("bookings")
        .select(
          `
          id,
          booking_code,
          customer_id,
          provider_id,
          provider:provider_profiles!bookings_provider_id_fkey(id, user:profiles(full_name)),
          menu:menus!bookings_menu_id_fkey(title)
        `
        )
        .order("created_at", { ascending: false });

      if (data && data.length > 0) {
        const list = data as unknown as ReviewableBooking[];
        setBookings(list);
        if (!selectedBookingId) {
          const match = list.find((b) => b.id === paramBookingId) || list[0];
          setSelectedBookingId(match.id);
        }
      }
    };
    loadBookings();
  }, [paramBookingId, selectedBookingId]);

  const currentBooking = bookings.find((b) => b.id === selectedBookingId) || bookings[0];

  const handleSubmitReview = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!currentBooking) return;
    setSubmitting(true);
    setErrorMsg(null);

    try {
      const { error } = await supabase.from("reviews").upsert(
        {
          booking_id: currentBooking.id,
          customer_id: userProfile?.id || currentBooking.customer_id,
          provider_id: currentBooking.provider_id,
          rating_food: ratingFood,
          rating_hygiene: ratingHygiene,
          rating_presentation: ratingPresentation,
          comment:
            comment.trim() ||
            "Yemeklerin lezzeti, sunumu ve mutfağın tertemiz bırakılması harikaydı!",
        },
        { onConflict: "booking_id" }
      );

      if (error) {
        setErrorMsg(error.message);
      } else {
        setSubmitted(true);
        setTimeout(() => {
          router.push(`/chef/${currentBooking.provider_id}`);
        }, 1200);
      }
    } finally {
      setSubmitting(false);
    }
  };

  const avgPreview = ((ratingFood + ratingHygiene + ratingPresentation) / 3).toFixed(2);

  return (
    <main className="pt-24 md:pt-28 px-6 max-w-2xl mx-auto w-full">
      <div className="mb-6">
        <Link
          href="/profile"
          className="flex items-center gap-2 text-sm font-semibold text-foreground hover:opacity-80 mb-4"
        >
          <ArrowLeft className="w-4 h-4" /> Profilime Dön
        </Link>
        <h1 className="font-serif text-3xl font-bold">3 Kriterli Deneyim Değerlendirmesi</h1>
        <p className="text-sm text-muted-foreground mt-1">
          Değerlendirmeniz şefin genel puan ortalamasını otomatik olarak günceller.
        </p>
      </div>

      <form
        onSubmit={handleSubmitReview}
        className="bg-card border border-border p-6 md:p-8 rounded-3xl shadow-sm space-y-6"
      >
        {/* Booking Selector */}
        <div>
          <label className="text-xs font-bold uppercase text-muted-foreground block mb-1.5">
            Değerlendirilen Rezervasyon
          </label>
          <select
            value={selectedBookingId}
            onChange={(e) => setSelectedBookingId(e.target.value)}
            className="w-full bg-background border border-border rounded-xl p-3 text-xs font-bold"
          >
            {bookings.map((b) => (
              <option key={b.id} value={b.id}>
                {b.booking_code} — {b.provider?.user?.full_name} ({b.menu?.title || "Özel Hizmet"})
              </option>
            ))}
          </select>
        </div>

        {/* 3 Criteria Rows */}
        <div className="space-y-3">
          <StarRow
            label="1. Lezzet & Reçete Kalitesi"
            subtitle="Tabakların pişirme tekniği, malzeme tazeliği ve lezzet dengesi"
            value={ratingFood}
            onChange={setRatingFood}
          />
          <StarRow
            label="2. Mutfak Temizliği & Hijyen"
            subtitle="Çalışma disiplini ve etkinlik sonunda mutfağın temiz teslim edilmesi"
            value={ratingHygiene}
            onChange={setRatingHygiene}
          />
          <StarRow
            label="3. Sunum & İletişim"
            subtitle="Zamanlama, masa sunumu ve misafirlerle iletişim"
            value={ratingPresentation}
            onChange={setRatingPresentation}
          />
        </div>

        <div className="flex items-center justify-between px-4 py-3 rounded-xl bg-secondary/10 border border-secondary/30 text-xs font-bold">
          <span>Hesaplanan Genel Puan Ortalaması:</span>
          <span className="text-secondary text-base font-serif">★ {avgPreview} / 5.00</span>
        </div>

        {/* Review Text */}
        <div>
          <label className="text-xs font-bold uppercase text-muted-foreground block mb-2">
            Yorumunuz & Deneyiminiz
          </label>
          <textarea
            rows={4}
            value={comment}
            onChange={(e) => setComment(e.target.value)}
            placeholder="Yemekler, sunum ve mutfak temizliği hakkındaki görüşlerinizi paylaşın..."
            className="w-full bg-transparent border border-border p-4 rounded-xl text-sm focus:outline-none focus:border-secondary"
          />
        </div>

        {errorMsg && (
          <div className="p-3 rounded-xl bg-destructive/10 text-destructive text-xs flex items-center gap-2">
            <AlertCircle className="w-4 h-4" />
            <span>{errorMsg}</span>
          </div>
        )}

        {submitted && (
          <div className="p-3 rounded-xl bg-emerald-500/10 text-emerald-600 text-xs font-bold flex items-center gap-2">
            <CheckCircle2 className="w-4 h-4" />
            <span>Değerlendirmeniz kaydedildi! Şef profiline yönlendiriliyorsunuz...</span>
          </div>
        )}

        <Button
          type="submit"
          disabled={submitting}
          className="w-full py-6 text-sm font-bold rounded-xl gap-2 cursor-pointer"
        >
          {submitting && <Loader2 className="w-4 h-4 animate-spin" />}
          Değerlendirmeyi Kaydet & Yayınla
        </Button>
      </form>
    </main>
  );
}

export default function ReviewPage() {
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
        <ReviewContent />
      </React.Suspense>
      <MobileBottomNav />
    </div>
  );
}
