"use client";

import * as React from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  ArrowLeft,
  MapPin,
  Utensils,
  Award,
  LogOut,
  ChefHat,
  ShieldCheck,
  MessageSquare,
  Star,
  Loader2,
  CheckCircle2,
} from "lucide-react";
import { Header } from "@/components/home/Header";
import { MobileBottomNav } from "@/components/home/MobileBottomNav";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { supabase } from "@/lib/supabase";
import { useAuth } from "@/lib/auth-context";

interface CustomerBookingRow {
  id: string;
  booking_code: string;
  event_date: string;
  event_time: string;
  guest_count: number;
  total_price: number;
  status: string;
  provider?: {
    id: string;
    user?: { full_name: string };
  };
  menu?: { title: string };
}

export default function ProfilePage() {
  const router = useRouter();
  const { userProfile, signOut, refreshProfile } = useAuth();

  const [bookings, setBookings] = React.useState<CustomerBookingRow[]>([]);
  const [loadingBookings, setLoadingBookings] = React.useState<boolean>(true);
  const [editing, setEditing] = React.useState<boolean>(false);
  const [fullName, setFullName] = React.useState<string>("");
  const [phone, setPhone] = React.useState<string>("");
  const [address, setAddress] = React.useState<string>("");
  const [saving, setSaving] = React.useState<boolean>(false);

  React.useEffect(() => {
    if (userProfile) {
      setFullName(userProfile.full_name || "");
      setPhone(userProfile.phone || "");
      setAddress(userProfile.default_address || "Kadıköy, İstanbul");
    }
  }, [userProfile]);

  React.useEffect(() => {
    const fetchUserBookings = async () => {
      setLoadingBookings(true);
      try {
        const { data } = await supabase
          .from("bookings")
          .select(
            `
            id,
            booking_code,
            event_date,
            event_time,
            guest_count,
            total_price,
            status,
            provider:provider_profiles!bookings_provider_id_fkey(id, user:profiles(full_name)),
            menu:menus!bookings_menu_id_fkey(title)
          `
          )
          .order("created_at", { ascending: false });

        if (data) {
          setBookings(data as unknown as CustomerBookingRow[]);
        }
      } finally {
        setLoadingBookings(false);
      }
    };
    fetchUserBookings();
  }, [userProfile?.id]);

  const handleSaveProfile = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!userProfile) return;
    setSaving(true);
    try {
      await supabase
        .from("profiles")
        .update({
          full_name: fullName.trim(),
          phone: phone.trim(),
          default_address: address.trim(),
        })
        .eq("id", userProfile.id);
      await refreshProfile();
      setEditing(false);
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="min-h-screen bg-background text-foreground antialiased pb-24 md:pb-16">
      <Header />

      <main className="pt-24 md:pt-28 px-6 md:px-12 max-w-5xl mx-auto w-full space-y-8">
        {/* Top Navigation */}
        <div className="flex flex-wrap items-center justify-between gap-3">
          <Link
            href="/"
            className="flex items-center gap-2 text-sm font-semibold text-foreground hover:opacity-80"
          >
            <ArrowLeft className="w-4 h-4" /> Keşfet Ekranına Dön
          </Link>

          <div className="flex items-center gap-2">
            <Link href="/chef-dashboard">
              <Button variant="outline" size="sm" className="gap-1.5 rounded-full text-xs">
                <ChefHat className="w-3.5 h-3.5 text-secondary" /> Şef Paneline Geç
              </Button>
            </Link>
            <Link href="/admin">
              <Button variant="outline" size="sm" className="gap-1.5 rounded-full text-xs">
                <ShieldCheck className="w-3.5 h-3.5 text-secondary" /> Admin Paneli
              </Button>
            </Link>
          </div>
        </div>

        {/* Profile Header Card */}
        <div className="bg-card border border-border p-6 md:p-8 rounded-3xl shadow-sm space-y-6">
          <div className="flex flex-col md:flex-row items-center md:items-start justify-between gap-6 border-b border-border pb-6">
            <div className="flex flex-col md:flex-row items-center md:items-start gap-4 text-center md:text-left">
              <div className="w-20 h-20 rounded-full bg-secondary/15 text-secondary border-2 border-secondary/30 flex items-center justify-center font-serif text-2xl font-bold overflow-hidden">
                {userProfile?.avatar_url ? (
                  <img
                    src={userProfile.avatar_url}
                    alt={userProfile.full_name}
                    className="w-full h-full object-cover"
                  />
                ) : (
                  (userProfile?.full_name || "GH").slice(0, 2).toUpperCase()
                )}
              </div>
              <div>
                <div className="flex flex-wrap items-center justify-center md:justify-start gap-2">
                  <h1 className="font-serif text-2xl font-bold">
                    {userProfile?.full_name || "Elif Demir"}
                  </h1>
                  <Badge variant="secondary" className="gap-1">
                    <Award className="w-3 h-3" /> Doğrulanmış Üye ({userProfile?.role || "customer"})
                  </Badge>
                </div>
                <p className="text-sm text-muted-foreground mt-1">
                  {userProfile?.email || "musteri@gastrohost.app"} •{" "}
                  {userProfile?.phone || "+90 532 888 11 22"}
                </p>
                <div className="flex items-center justify-center md:justify-start gap-2 text-xs text-muted-foreground mt-2">
                  <MapPin className="w-3.5 h-3.5 text-secondary" />
                  <span>{userProfile?.default_address || "Kadıköy / İstanbul"}</span>
                </div>
              </div>
            </div>

            <div className="flex items-center gap-2">
              <Button
                variant="outline"
                onClick={() => setEditing((prev) => !prev)}
                className="rounded-full text-xs"
              >
                {editing ? "Kapat" : "Profili Düzenle"}
              </Button>
              <Link href="/login">
                <Button variant="secondary" className="rounded-full text-xs font-bold">
                  Hesap Değiştir
                </Button>
              </Link>
            </div>
          </div>

          {editing && (
            <form
              onSubmit={handleSaveProfile}
              className="grid grid-cols-1 md:grid-cols-3 gap-4 pt-2 border-b border-border pb-6"
            >
              <div>
                <label className="text-xs font-bold uppercase text-muted-foreground block mb-1">
                  Ad Soyad
                </label>
                <Input value={fullName} onChange={(e) => setFullName(e.target.value)} />
              </div>
              <div>
                <label className="text-xs font-bold uppercase text-muted-foreground block mb-1">
                  Telefon
                </label>
                <Input value={phone} onChange={(e) => setPhone(e.target.value)} />
              </div>
              <div>
                <label className="text-xs font-bold uppercase text-muted-foreground block mb-1">
                  Varsayılan Adres
                </label>
                <div className="flex gap-2">
                  <Input value={address} onChange={(e) => setAddress(e.target.value)} />
                  <Button type="submit" disabled={saving} className="shrink-0">
                    {saving ? <Loader2 className="w-4 h-4 animate-spin" /> : "Kaydet"}
                  </Button>
                </div>
              </div>
            </form>
          )}

          {/* Stats Bar */}
          <div className="grid grid-cols-3 gap-4 text-center">
            <div>
              <div className="font-serif text-2xl font-bold text-foreground">
                {bookings.length}
              </div>
              <div className="text-xs text-muted-foreground font-medium mt-0.5">
                Toplam Rezervasyon
              </div>
            </div>
            <div className="border-x border-border">
              <div className="font-serif text-2xl font-bold text-emerald-600">%100</div>
              <div className="text-xs text-muted-foreground font-medium mt-0.5">
                Escrow Ödeme Güvencesi
              </div>
            </div>
            <div>
              <div className="font-serif text-2xl font-bold text-secondary">%10</div>
              <div className="text-xs text-muted-foreground font-medium mt-0.5">
                Standart Platform Komisyonu
              </div>
            </div>
          </div>
        </div>

        {/* Bookings & Culinary Passport Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
          <div className="lg:col-span-8 space-y-4">
            <h2 className="font-serif text-2xl font-bold">Aktif & Geçmiş Rezervasyonlarım</h2>

            {loadingBookings ? (
              <div className="py-12 flex justify-center">
                <Loader2 className="w-6 h-6 animate-spin text-secondary" />
              </div>
            ) : (
              <div className="space-y-3">
                {bookings.map((b) => (
                  <div
                    key={b.id}
                    className="bg-card border border-border p-5 rounded-2xl flex flex-col sm:flex-row sm:items-center justify-between gap-4 hover:border-secondary/50 transition"
                  >
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="font-mono text-xs font-bold px-2 py-0.5 rounded bg-muted">
                          {b.booking_code}
                        </span>
                        <span className="font-bold text-sm">
                          {b.provider?.user?.full_name || "Özel Şef"}
                        </span>
                        <Badge variant="secondary" className="text-[10px]">
                          {b.status === "pending"
                            ? "Onay Bekliyor"
                            : b.status === "accepted" || b.status === "confirmed"
                            ? "Onaylandı"
                            : b.status === "shopping"
                            ? "Malzeme Tedarikinde"
                            : b.status === "on_the_way"
                            ? "Yolda"
                            : b.status === "in_kitchen"
                            ? "Mutfakta"
                            : b.status === "completed"
                            ? "Tamamlandı"
                            : b.status === "cancelled"
                            ? "İptal Edildi"
                            : b.status}
                        </Badge>
                      </div>
                      <div className="text-xs text-muted-foreground mt-1">
                        {b.menu?.title || "Özel Tadım Menüsü"} • {b.event_date} (
                        {b.event_time?.slice(0, 5)}) • {b.guest_count} Kişi •{" "}
                        <strong className="text-foreground">
                          ₺{Number(b.total_price).toLocaleString("tr-TR")}
                        </strong>
                      </div>
                    </div>

                    <div className="flex items-center gap-2">
                      <Link href={`/tracker?bookingId=${b.id}`}>
                        <Button size="sm" className="rounded-xl text-xs font-bold">
                          Canlı Takip
                        </Button>
                      </Link>
                      <Link href={`/chat?bookingId=${b.id}`}>
                        <Button size="sm" variant="outline" className="rounded-xl text-xs gap-1">
                          <MessageSquare className="w-3.5 h-3.5 text-secondary" /> Sohbet
                        </Button>
                      </Link>
                      <Link href={`/review?bookingId=${b.id}`}>
                        <Button size="sm" variant="outline" className="rounded-xl text-xs gap-1">
                          <Star className="w-3.5 h-3.5 text-secondary" /> Puanla
                        </Button>
                      </Link>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Right Column: Kitchen & Allergy Passport */}
          <div className="lg:col-span-4 space-y-6">
            <div className="bg-card border border-border p-6 rounded-2xl shadow-sm space-y-4">
              <h2 className="font-serif text-lg font-bold flex items-center gap-2">
                <Utensils className="w-5 h-5 text-secondary" /> Mutfak & Alerjen Pasaportum
              </h2>
              <p className="text-xs text-muted-foreground">
                Rezervasyon sırasında şeflerle otomatik paylaşılan kayıtlı mutfak donanımınız.
              </p>
              <div className="flex flex-wrap gap-1.5">
                <Badge variant="outline">4 Gözlü İndüksiyon Ocak</Badge>
                <Badge variant="outline">Konveksiyonel Fırın</Badge>
                <Badge variant="outline">Blender / Robot</Badge>
                <Badge variant="secondary">✓ Güvenli Mutfak Onaylı</Badge>
              </div>
            </div>

            <div className="bg-card border border-border p-6 rounded-2xl shadow-sm space-y-3">
              <div className="flex items-center gap-2 text-xs text-emerald-600 font-bold">
                <CheckCircle2 className="w-4 h-4" />
                <span>Hesap Bilgileriniz Güncel</span>
              </div>
              <button
                onClick={async () => {
                  await signOut();
                  router.push("/login");
                }}
                className="w-full pt-3 border-t border-border flex items-center gap-2 text-destructive text-xs font-bold cursor-pointer"
              >
                <LogOut className="w-4 h-4" /> Oturumu Kapat
              </button>
            </div>
          </div>
        </div>
      </main>

      <MobileBottomNav />
    </div>
  );
}
