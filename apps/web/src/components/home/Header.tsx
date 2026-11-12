"use client";

import * as React from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import {
  MapPin,
  ChevronDown,
  User,
  Loader2,
  Bell,
  ChefHat,
  ShieldCheck,
  Compass,
  Activity,
  LogOut,
  CheckCheck,
  Sparkles,
} from "lucide-react";
import { useAuth, ISTANBUL_DISTRICTS } from "@/lib/auth-context";
import { DEMO_ACCOUNTS } from "@/lib/supabase";

export function Header() {
  const pathname = usePathname();
  const router = useRouter();
  const {
    userProfile,
    notifications,
    unreadCount,
    userLocation,
    setUserLocation,
    signInWithDemoAccount,
    signOut,
    markNotificationAsRead,
    markAllNotificationsAsRead,
  } = useAuth();

  const headerRef = React.useRef<HTMLElement | null>(null);
  const [isDetecting, setIsDetecting] = React.useState(false);
  const [showLocationMenu, setShowLocationMenu] = React.useState(false);
  const [showNotifMenu, setShowNotifMenu] = React.useState(false);
  const [showUserMenu, setShowUserMenu] = React.useState(false);
  const [switchingEmail, setSwitchingEmail] = React.useState<string | null>(null);

  // Close all dropdowns on route change
  React.useEffect(() => {
    setShowLocationMenu(false);
    setShowNotifMenu(false);
    setShowUserMenu(false);
  }, [pathname]);

  // Close dropdowns when clicking outside or pressing Escape
  React.useEffect(() => {
    const handlePointerDown = (e: MouseEvent) => {
      if (headerRef.current && !headerRef.current.contains(e.target as Node)) {
        setShowLocationMenu(false);
        setShowNotifMenu(false);
        setShowUserMenu(false);
      }
    };

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        setShowLocationMenu(false);
        setShowNotifMenu(false);
        setShowUserMenu(false);
      }
    };

    document.addEventListener("mousedown", handlePointerDown);
    document.addEventListener("keydown", handleKeyDown);
    return () => {
      document.removeEventListener("mousedown", handlePointerDown);
      document.removeEventListener("keydown", handleKeyDown);
    };
  }, []);

  const handleDetectLocation = () => {
    if ("geolocation" in navigator) {
      setIsDetecting(true);
      navigator.geolocation.getCurrentPosition(
        async (position) => {
          try {
            const { latitude, longitude } = position.coords;
            const res = await fetch(
              `https://nominatim.openstreetmap.org/reverse?format=json&lat=${latitude}&lon=${longitude}`
            );
            const data = await res.json();
            const district =
              data.address?.suburb ||
              data.address?.town ||
              data.address?.city_district ||
              "Kadıköy";
            const city = data.address?.city || data.address?.province || "İstanbul";
            setUserLocation({
              label: `${district}, ${city}`,
              lat: latitude,
              lng: longitude,
            });
          } catch {
            setUserLocation({
              label: "Kadıköy, İstanbul (GPS)",
              lat: 40.9819,
              lng: 29.0254,
            });
          } finally {
            setIsDetecting(false);
            setShowLocationMenu(false);
          }
        },
        () => {
          setIsDetecting(false);
          setShowLocationMenu(false);
        }
      );
    }
  };

  const handleQuickSwitch = async (email: string, redirectPath: string) => {
    setSwitchingEmail(email);
    await signInWithDemoAccount(email);
    setSwitchingEmail(null);
    setShowUserMenu(false);
    router.push(redirectPath);
  };

  const roleBadgeLabel =
    userProfile?.role === "admin"
      ? "Admin"
      : userProfile?.role === "chef"
      ? "Özel Şef"
      : userProfile?.role === "bartender"
      ? "Miksolojist"
      : "Müşteri";

  return (
    <header
      ref={headerRef}
      className="fixed top-0 w-full z-[1100] bg-white/95 backdrop-blur-xl border-b border-stone-200/90 shadow-2xs transition-colors"
    >
      <div className="flex items-center justify-between px-4 md:px-10 w-full max-w-7xl mx-auto py-3.5">
        {/* Left: Brand & Location Picker */}
        <div className="flex items-center gap-4 md:gap-6">
          <Link
            href="/"
            className="flex items-center gap-2.5 font-serif font-bold text-xl text-stone-950 shrink-0"
          >
            <span className="w-9 h-9 rounded-full bg-amber-800 flex items-center justify-center text-white font-serif text-sm font-bold shadow-sm">
              GH
            </span>
            <span className="hidden sm:inline tracking-tight">GastroHost</span>
          </Link>

          {/* Dynamic Location Picker Dropdown */}
          <div className="relative">
            <button
              type="button"
              onClick={() => {
                setShowLocationMenu((prev) => !prev);
                setShowNotifMenu(false);
                setShowUserMenu(false);
              }}
              className="flex items-center gap-1.5 text-stone-900 hover:bg-stone-200/70 transition-colors px-3 py-1.5 rounded-full bg-stone-100 border border-stone-200/90 text-xs md:text-sm cursor-pointer"
            >
              <MapPin className="w-4 h-4 text-amber-800 shrink-0" />
              {isDetecting ? (
                <span className="flex items-center gap-1.5 text-amber-800 font-medium">
                  <Loader2 className="w-3.5 h-3.5 animate-spin" /> Konum Alınıyor...
                </span>
              ) : (
                <>
                  <span className="font-semibold truncate max-w-[140px] md:max-w-[200px]">
                    {userLocation.label}
                  </span>
                  <ChevronDown
                    className={`w-3.5 h-3.5 text-amber-800 shrink-0 transition-transform duration-200 ${
                      showLocationMenu ? "rotate-180" : ""
                    }`}
                  />
                </>
              )}
            </button>

            {showLocationMenu && (
              <div className="absolute left-0 mt-2.5 w-68 bg-white text-stone-900 border border-stone-200 rounded-2xl shadow-2xl ring-1 ring-black/5 p-2.5 z-[1200] space-y-1">
                <div className="px-3 py-1.5 text-[11px] font-extrabold uppercase tracking-wider text-stone-500">
                  Etkinlik Bölgesi Seçin
                </div>
                {ISTANBUL_DISTRICTS.map((dist) => {
                  const isCurrent = userLocation.label === dist.label;
                  return (
                    <button
                      type="button"
                      key={dist.label}
                      onClick={() => {
                        setUserLocation(dist);
                        setShowLocationMenu(false);
                      }}
                      className={`w-full text-left px-3 py-2 rounded-xl text-xs font-medium flex items-center justify-between transition cursor-pointer ${
                        isCurrent
                          ? "bg-amber-800/12 text-amber-900 font-bold"
                          : "hover:bg-stone-100 text-stone-800"
                      }`}
                    >
                      <span>📍 {dist.label}</span>
                      {isCurrent && (
                        <span className="text-amber-800 font-extrabold">
                          ✓
                        </span>
                      )}
                    </button>
                  );
                })}
                <div className="pt-1.5 mt-1 border-t border-stone-200">
                  <button
                    type="button"
                    onClick={handleDetectLocation}
                    className="w-full text-left px-3 py-2 rounded-xl text-xs font-bold text-amber-800 hover:bg-amber-50 flex items-center gap-2 transition cursor-pointer"
                  >
                    <MapPin className="w-3.5 h-3.5" /> GPS ile Mevcut Konumu Bul
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Center: Desktop Role Navigation Links */}
        <nav className="hidden lg:flex items-center gap-1 bg-stone-100 p-1 rounded-full border border-stone-200/80">
          <Link
            href="/"
            className={`flex items-center gap-1.5 px-3.5 py-1.5 rounded-full text-xs font-semibold transition ${
              pathname === "/"
                ? "bg-stone-900 text-white shadow-xs"
                : "text-stone-600 hover:text-stone-950"
            }`}
          >
            <Compass className="w-3.5 h-3.5" /> Keşfet
          </Link>
          <Link
            href="/tracker"
            className={`flex items-center gap-1.5 px-3.5 py-1.5 rounded-full text-xs font-semibold transition ${
              pathname.startsWith("/tracker") || pathname.startsWith("/chat")
                ? "bg-stone-900 text-white shadow-xs"
                : "text-stone-600 hover:text-stone-950"
            }`}
          >
            <Activity className="w-3.5 h-3.5" /> Canlı Takip
          </Link>
          <Link
            href="/chef-dashboard"
            className={`flex items-center gap-1.5 px-3.5 py-1.5 rounded-full text-xs font-semibold transition ${
              pathname.startsWith("/chef-dashboard")
                ? "bg-stone-900 text-white shadow-xs"
                : "text-stone-600 hover:text-stone-950"
            }`}
          >
            <ChefHat className="w-3.5 h-3.5" /> Şef & Barmen Paneli
          </Link>
          <Link
            href="/admin"
            className={`flex items-center gap-1.5 px-3.5 py-1.5 rounded-full text-xs font-semibold transition ${
              pathname.startsWith("/admin")
                ? "bg-stone-900 text-white shadow-xs"
                : "text-stone-600 hover:text-stone-950"
            }`}
          >
            <ShieldCheck className="w-3.5 h-3.5 text-amber-700" /> Admin Paneli
          </Link>
        </nav>

        {/* Right: Notifications & User / Role Switcher */}
        <div className="flex items-center gap-2.5">
          {/* Notifications Bell */}
          <div className="relative">
            <button
              type="button"
              aria-label="Bildirimler"
              onClick={() => {
                setShowNotifMenu((prev) => !prev);
                setShowUserMenu(false);
                setShowLocationMenu(false);
              }}
              className="relative p-2 rounded-full bg-stone-100 border border-stone-200/80 hover:bg-stone-200/70 transition-colors text-stone-900 cursor-pointer"
            >
              <Bell className="w-4.5 h-4.5" />
              {unreadCount > 0 && (
                <span className="absolute -top-1 -right-1 w-4.5 h-4.5 rounded-full bg-amber-800 text-white text-[10px] font-bold flex items-center justify-center shadow-xs">
                  {unreadCount}
                </span>
              )}
            </button>

            {showNotifMenu && (
              <div className="absolute right-0 mt-2.5 w-84 bg-white text-stone-900 border border-stone-200 rounded-2xl shadow-2xl ring-1 ring-black/5 p-3.5 z-[1200] space-y-2.5">
                <div className="flex items-center justify-between border-b border-stone-200 pb-2.5">
                  <span className="text-xs font-extrabold uppercase tracking-wider text-stone-600">
                    Bildirimler ({notifications.length})
                  </span>
                  {unreadCount > 0 && (
                    <button
                      type="button"
                      onClick={markAllNotificationsAsRead}
                      className="text-[11px] font-bold text-amber-800 hover:underline flex items-center gap-1 cursor-pointer"
                    >
                      <CheckCheck className="w-3.5 h-3.5" /> Tümünü Okundu İşaretle
                    </button>
                  )}
                </div>

                {notifications.length === 0 ? (
                  <div className="py-8 text-center text-xs text-stone-500">
                    Henüz bildiriminiz bulunmuyor.
                  </div>
                ) : (
                  <div className="max-h-72 overflow-y-auto space-y-2 pr-0.5">
                    {notifications.map((n) => (
                      <div
                        key={n.id}
                        onClick={() => markNotificationAsRead(n.id)}
                        className={`p-3 rounded-xl border text-xs cursor-pointer transition ${
                          n.is_read
                            ? "bg-stone-50 border-stone-200/80 text-stone-600"
                            : "bg-amber-50/90 border-amber-300 text-stone-900 shadow-2xs"
                        }`}
                      >
                        <div className="font-bold text-stone-900">
                          {n.title}
                        </div>
                        <div className="text-[11px] mt-1 leading-relaxed text-stone-600">
                          {n.body}
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            )}
          </div>

          {/* Active User & Quick Switcher Dropdown */}
          <div className="relative">
            <button
              type="button"
              onClick={() => {
                setShowUserMenu((prev) => !prev);
                setShowNotifMenu(false);
                setShowLocationMenu(false);
              }}
              className="flex items-center gap-2 pl-2 pr-3 py-1.5 rounded-full bg-white border border-stone-200 hover:border-amber-800/60 transition shadow-2xs cursor-pointer"
            >
              <div className="w-7 h-7 rounded-full bg-amber-800/15 text-amber-900 font-bold text-xs flex items-center justify-center overflow-hidden">
                {userProfile?.avatar_url ? (
                  <img
                    src={userProfile.avatar_url}
                    alt={userProfile.full_name}
                    className="w-full h-full object-cover"
                  />
                ) : (
                  <User className="w-4 h-4" />
                )}
              </div>
              <div className="hidden sm:flex flex-col items-start text-left">
                <span className="text-xs font-bold leading-none text-stone-900 truncate max-w-[115px]">
                  {userProfile ? userProfile.full_name : "Giriş Yap"}
                </span>
                <span className="text-[10px] text-amber-800 font-bold mt-0.5">
                  {userProfile ? roleBadgeLabel : "Misafir"}
                </span>
              </div>
              <ChevronDown
                className={`w-3.5 h-3.5 text-stone-500 transition-transform duration-200 ${
                  showUserMenu ? "rotate-180" : ""
                }`}
              />
            </button>

            {showUserMenu && (
              <div className="absolute right-0 mt-2.5 w-76 bg-white text-stone-900 border border-stone-200 rounded-2xl shadow-2xl ring-1 ring-black/5 p-3.5 z-[1200] space-y-3">
                {userProfile ? (
                  <div className="border-b border-stone-200 pb-3">
                    <div className="font-bold text-sm text-stone-900">
                      {userProfile.full_name}
                    </div>
                    <div className="text-xs text-stone-500">
                      {userProfile.email}
                    </div>
                    <div className="flex items-center gap-2 mt-2.5">
                      <Link
                        href="/profile"
                        onClick={() => setShowUserMenu(false)}
                        className="flex-1 text-center py-1.5 px-2.5 rounded-xl bg-stone-100 hover:bg-stone-200 text-stone-900 text-xs font-bold transition"
                      >
                        Profilim
                      </Link>
                      <Link
                        href="/login"
                        onClick={() => setShowUserMenu(false)}
                        className="flex-1 text-center py-1.5 px-2.5 rounded-xl bg-amber-800/12 text-amber-900 hover:bg-amber-800/20 text-xs font-bold transition"
                      >
                        Hesap Değiştir
                      </Link>
                    </div>
                  </div>
                ) : (
                  <div className="border-b border-stone-200 pb-3">
                    <Link
                      href="/login"
                      onClick={() => setShowUserMenu(false)}
                      className="block w-full text-center py-2.5 rounded-xl bg-stone-900 text-white text-xs font-bold shadow-xs"
                    >
                      Giriş Yap / Kayıt Ol
                    </Link>
                  </div>
                )}

                {/* Quick Demo Account Switcher */}
                <div className="space-y-1.5">
                  <div className="flex items-center gap-1.5 text-[11px] font-extrabold uppercase tracking-wider text-stone-500 px-1">
                    <Sparkles className="w-3.5 h-3.5 text-amber-700" /> Hızlı Rol / Hesap Geçişi
                  </div>
                  {DEMO_ACCOUNTS.map((acc) => {
                    const isCurrent = userProfile?.email === acc.email;
                    const isBusy = switchingEmail === acc.email;
                    return (
                      <button
                        type="button"
                        key={acc.email}
                        disabled={isBusy}
                        onClick={() => handleQuickSwitch(acc.email, acc.redirectPath)}
                        className={`w-full text-left p-2.5 rounded-xl border text-xs transition flex items-center justify-between cursor-pointer ${
                          isCurrent
                            ? "bg-amber-50 border-amber-700 text-stone-900 font-bold"
                            : "bg-stone-50/70 border-stone-200/80 hover:bg-stone-100 text-stone-800"
                        }`}
                      >
                        <div>
                          <div className="font-bold">{acc.fullName}</div>
                          <div className="text-[10px] text-stone-500">
                            {acc.badge}
                          </div>
                        </div>
                        {isBusy ? (
                          <Loader2 className="w-3.5 h-3.5 animate-spin text-amber-800" />
                        ) : isCurrent ? (
                          <span className="text-[10px] font-extrabold px-2 py-0.5 rounded-full bg-amber-800 text-white">
                            Aktif
                          </span>
                        ) : null}
                      </button>
                    );
                  })}
                </div>

                {userProfile && (
                  <div className="pt-2 border-t border-stone-200">
                    <button
                      type="button"
                      onClick={async () => {
                        await signOut();
                        setShowUserMenu(false);
                        router.push("/login");
                      }}
                      className="w-full flex items-center justify-center gap-1.5 py-2 rounded-xl text-xs font-bold text-red-600 hover:bg-red-50 transition cursor-pointer"
                    >
                      <LogOut className="w-3.5 h-3.5" /> Çıkış Yap
                    </button>
                  </div>
                )}
              </div>
            )}
          </div>
        </div>
      </div>
    </header>
  );
}
