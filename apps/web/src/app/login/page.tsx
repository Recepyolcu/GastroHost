"use client";

import * as React from "react";
import { useRouter } from "next/navigation";
import {
  ChefHat,
  User,
  ShieldCheck,
  Wine,
  Loader2,
  CheckCircle2,
  AlertCircle,
  Sparkles,
  ArrowRight,
  Lock,
} from "lucide-react";
import { Header } from "@/components/home/Header";
import { MobileBottomNav } from "@/components/home/MobileBottomNav";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { useAuth } from "@/lib/auth-context";
import { DEMO_ACCOUNTS, UserRole } from "@/lib/supabase";

export default function LoginPage() {
  const router = useRouter();
  const {
    userProfile,
    signInWithEmail,
    signUpWithEmail,
    signInWithGoogle,
    signInWithDemoAccount,
  } = useAuth();

  const [authMode, setAuthMode] = React.useState<"login" | "register">("login");
  const [role, setRole] = React.useState<UserRole>("customer");
  const [email, setEmail] = React.useState("");
  const [password, setPassword] = React.useState("");
  const [fullName, setFullName] = React.useState("");
  const [phone, setPhone] = React.useState("");

  const [submitting, setSubmitting] = React.useState(false);
  const [googleLoading, setGoogleLoading] = React.useState(false);
  const [demoLoadingEmail, setDemoLoadingEmail] = React.useState<string | null>(null);
  const [errorMsg, setErrorMsg] = React.useState<string | null>(null);
  const [successMsg, setSuccessMsg] = React.useState<string | null>(null);

  const getRedirectByRole = (r?: UserRole) => {
    if (r === "admin") return "/admin";
    if (r === "chef" || r === "bartender") return "/chef-dashboard";
    return "/";
  };

  const handleFormSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg(null);
    setSuccessMsg(null);

    if (!email.trim() || !password.trim()) {
      setErrorMsg("Lütfen e-posta adresinizi ve şifrenizi giriniz.");
      return;
    }

    setSubmitting(true);
    try {
      if (authMode === "login") {
        const { error, profile } = await signInWithEmail(email, password);
        if (error) {
          setErrorMsg(
            error.includes("Invalid login credentials")
              ? "E-posta veya şifre hatalı. Demo hesaplarla tek tıkla giriş yapabilirsiniz."
              : error
          );
        } else {
          setSuccessMsg("Giriş başarılı, yönlendiriliyorsunuz...");
          router.push(getRedirectByRole(profile?.role || role));
        }
      } else {
        if (!fullName.trim()) {
          setErrorMsg("Lütfen adınızı ve soyadınızı giriniz.");
          setSubmitting(false);
          return;
        }
        const { error, profile } = await signUpWithEmail(
          email,
          password,
          fullName,
          role,
          phone
        );
        if (error) {
          setErrorMsg(error);
        } else {
          setSuccessMsg("Hesabınız oluşturuldu! Yönlendiriliyorsunuz...");
          router.push(getRedirectByRole(profile?.role || role));
        }
      }
    } finally {
      setSubmitting(false);
    }
  };

  const handleGoogleSignIn = async () => {
    setErrorMsg(null);
    setGoogleLoading(true);
    const { error } = await signInWithGoogle(role);
    if (error) {
      setErrorMsg(error);
      setGoogleLoading(false);
    }
  };

  const handleDemoLogin = async (presetEmail: string, redirectPath: string) => {
    setErrorMsg(null);
    setSuccessMsg(null);
    setDemoLoadingEmail(presetEmail);
    try {
      const { error } = await signInWithDemoAccount(presetEmail);
      if (error) {
        setErrorMsg(`Demo giriş hatası: ${error}`);
      } else {
        setSuccessMsg("Oturum açıldı, yönlendiriliyorsunuz...");
        router.push(redirectPath);
      }
    } finally {
      setDemoLoadingEmail(null);
    }
  };

  return (
    <div className="min-h-screen bg-background text-foreground antialiased pb-24 md:pb-16">
      <Header />

      <main className="pt-24 md:pt-32 px-6 max-w-5xl mx-auto w-full">
        {/* Brand Header */}
        <div className="text-center max-w-xl mx-auto mb-10">
          <Badge variant="secondary" className="mb-3 px-3 py-1 text-xs font-semibold">
            GastroHost Kimlik & Oturum Merkezi
          </Badge>
          <h1 className="font-serif text-3xl md:text-4xl font-bold mb-2">
            GastroHost&apos;a Hoş Geldiniz
          </h1>
          <p className="text-sm text-muted-foreground">
            Mobil uygulamamızla %100 senkronize hesabınızla giriş yapın, Google ile bağlanın veya
            canlı veritabanındaki hazır profillerle hemen deneyimleyin.
          </p>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
          {/* Left Column: Standard Login / Register + Google OAuth */}
          <div className="lg:col-span-7 bg-card border border-border p-6 md:p-8 rounded-2xl shadow-sm space-y-6">
            {/* Login / Register Switch */}
            <div className="flex bg-muted/60 p-1 rounded-xl border border-border/60">
              <button
                type="button"
                onClick={() => {
                  setAuthMode("login");
                  setErrorMsg(null);
                }}
                className={`flex-1 py-2.5 text-xs font-bold rounded-lg transition ${
                  authMode === "login"
                    ? "bg-card text-foreground shadow-sm"
                    : "text-muted-foreground hover:text-foreground"
                }`}
              >
                Giriş Yap
              </button>
              <button
                type="button"
                onClick={() => {
                  setAuthMode("register");
                  setErrorMsg(null);
                }}
                className={`flex-1 py-2.5 text-xs font-bold rounded-lg transition ${
                  authMode === "register"
                    ? "bg-card text-foreground shadow-sm"
                    : "text-muted-foreground hover:text-foreground"
                }`}
              >
                Yeni Hesap Oluştur
              </button>
            </div>

            {/* Role Toggle Tabs */}
            <div>
              <label className="text-[11px] font-bold uppercase text-muted-foreground block mb-2">
                Hangi Rol İle Devam Etmek İstiyorsunuz?
              </label>
              <div className="grid grid-cols-3 gap-2">
                <button
                  type="button"
                  onClick={() => setRole("customer")}
                  className={`flex items-center justify-center gap-1.5 py-2.5 px-3 rounded-xl border text-xs font-semibold transition ${
                    role === "customer"
                      ? "border-secondary bg-secondary/10 text-foreground"
                      : "border-border text-muted-foreground hover:text-foreground"
                  }`}
                >
                  <User className="w-3.5 h-3.5 text-secondary" /> Müşteri
                </button>
                <button
                  type="button"
                  onClick={() => setRole("chef")}
                  className={`flex items-center justify-center gap-1.5 py-2.5 px-3 rounded-xl border text-xs font-semibold transition ${
                    role === "chef"
                      ? "border-secondary bg-secondary/10 text-foreground"
                      : "border-border text-muted-foreground hover:text-foreground"
                  }`}
                >
                  <ChefHat className="w-3.5 h-3.5 text-secondary" /> Özel Şef
                </button>
                <button
                  type="button"
                  onClick={() => setRole("bartender")}
                  className={`flex items-center justify-center gap-1.5 py-2.5 px-3 rounded-xl border text-xs font-semibold transition ${
                    role === "bartender"
                      ? "border-secondary bg-secondary/10 text-foreground"
                      : "border-border text-muted-foreground hover:text-foreground"
                  }`}
                >
                  <Wine className="w-3.5 h-3.5 text-secondary" /> Barmen
                </button>
              </div>
            </div>

            {/* Google OAuth Button (Same as Mobile App) */}
            <div>
              <button
                type="button"
                onClick={handleGoogleSignIn}
                disabled={googleLoading}
                className="w-full flex items-center justify-center gap-3 py-3.5 px-4 rounded-xl border border-border bg-background hover:bg-muted/60 text-foreground text-sm font-semibold transition shadow-xs cursor-pointer"
              >
                {googleLoading ? (
                  <Loader2 className="w-4 h-4 animate-spin text-secondary" />
                ) : (
                  <svg className="w-5 h-5" viewBox="0 0 24 24">
                    <path
                      fill="#4285F4"
                      d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                    />
                    <path
                      fill="#34A853"
                      d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                    />
                    <path
                      fill="#FBBC05"
                      d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
                    />
                    <path
                      fill="#EA4335"
                      d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                    />
                  </svg>
                )}
                <span>Google ile {authMode === "login" ? "Giriş Yap" : "Kayıt Ol"}</span>
              </button>
            </div>

            <div className="relative flex py-1 items-center">
              <div className="grow border-t border-border" />
              <span className="shrink mx-3 text-[11px] uppercase font-bold text-muted-foreground">
                veya E-posta ile
              </span>
              <div className="grow border-t border-border" />
            </div>

            {errorMsg && (
              <div className="p-3.5 rounded-xl bg-destructive/10 border border-destructive/30 text-destructive text-xs font-medium flex items-center gap-2">
                <AlertCircle className="w-4 h-4 shrink-0" />
                <span>{errorMsg}</span>
              </div>
            )}

            {successMsg && (
              <div className="p-3.5 rounded-xl bg-emerald-500/10 border border-emerald-500/30 text-emerald-600 text-xs font-medium flex items-center gap-2">
                <CheckCircle2 className="w-4 h-4 shrink-0" />
                <span>{successMsg}</span>
              </div>
            )}

            {/* Email & Password Form */}
            <form onSubmit={handleFormSubmit} className="space-y-4">
              {authMode === "register" && (
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div>
                    <label className="text-xs font-bold uppercase text-muted-foreground block mb-1.5">
                      Ad Soyad
                    </label>
                    <Input
                      value={fullName}
                      onChange={(e) => setFullName(e.target.value)}
                      placeholder="Örn: Ahmet Yılmaz"
                    />
                  </div>
                  <div>
                    <label className="text-xs font-bold uppercase text-muted-foreground block mb-1.5">
                      Telefon Numarası
                    </label>
                    <Input
                      value={phone}
                      onChange={(e) => setPhone(e.target.value)}
                      placeholder="+90 532 000 00 00"
                    />
                  </div>
                </div>
              )}

              <div>
                <label className="text-xs font-bold uppercase text-muted-foreground block mb-1.5">
                  E-posta Adresi
                </label>
                <Input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="ornek@gastrohost.app"
                />
              </div>

              <div>
                <label className="text-xs font-bold uppercase text-muted-foreground block mb-1.5">
                  Şifre
                </label>
                <Input
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                />
              </div>

              <Button
                type="submit"
                disabled={submitting}
                className="w-full py-6 text-sm font-bold rounded-xl mt-2 gap-2"
              >
                {submitting && <Loader2 className="w-4 h-4 animate-spin" />}
                {authMode === "login" ? "E-posta ile Giriş Yap" : "Hesabımı Oluştur"}
              </Button>
            </form>
          </div>

          {/* Right Column: Instant Live Demo Accounts (Real Supabase Sessions) */}
          <div className="lg:col-span-5 bg-card border border-border p-6 md:p-8 rounded-2xl shadow-sm space-y-5">
            <div className="flex items-center gap-2.5">
              <div className="w-9 h-9 rounded-xl bg-secondary/15 text-secondary flex items-center justify-center">
                <Sparkles className="w-5 h-5" />
              </div>
              <div>
                <h2 className="font-serif text-lg font-bold">
                  Tek Tıkla Hızlı Test Hesapları
                </h2>
                <p className="text-xs text-muted-foreground">
                  Farklı kullanıcı rollerini (Müşteri, Şef, Miksolojist, Admin) tek tıkla deneyimleyin.
                </p>
              </div>
            </div>

            <div className="space-y-3">
              {DEMO_ACCOUNTS.map((acc) => {
                const isCurrent = userProfile?.email === acc.email;
                const isBusy = demoLoadingEmail === acc.email;

                return (
                  <div
                    key={acc.email}
                    className={`p-4 rounded-xl border transition ${
                      isCurrent
                        ? "border-secondary bg-secondary/10"
                        : "border-border hover:border-secondary/50 bg-background/50"
                    }`}
                  >
                    <div className="flex items-start justify-between gap-2">
                      <div>
                        <div className="flex items-center gap-2">
                          <span className="font-bold text-sm text-foreground">
                            {acc.fullName}
                          </span>
                          <Badge variant="secondary" className="text-[10px]">
                            {acc.badge}
                          </Badge>
                        </div>
                        <div className="text-[11px] text-muted-foreground font-mono mt-0.5">
                          {acc.email}
                        </div>
                      </div>
                      {isCurrent && (
                        <span className="text-[10px] font-bold text-emerald-600 bg-emerald-500/10 px-2 py-0.5 rounded-full">
                          Aktif Oturum
                        </span>
                      )}
                    </div>

                    <p className="text-xs text-muted-foreground mt-2 leading-relaxed">
                      {acc.description}
                    </p>

                    <Button
                      type="button"
                      variant={isCurrent ? "secondary" : "outline"}
                      size="sm"
                      disabled={isBusy}
                      onClick={() => handleDemoLogin(acc.email, acc.redirectPath)}
                      className="w-full mt-3 rounded-lg text-xs font-bold gap-1.5"
                    >
                      {isBusy ? (
                        <Loader2 className="w-3.5 h-3.5 animate-spin" />
                      ) : (
                        <>
                          <span>{isCurrent ? "Paneline Git" : "Bu Hesapla Giriş Yap"}</span>
                          <ArrowRight className="w-3.5 h-3.5" />
                        </>
                      )}
                    </Button>
                  </div>
                );
              })}
            </div>

            <div className="p-3.5 rounded-xl bg-muted/60 border border-border/60 flex items-start gap-2.5 text-xs text-muted-foreground">
              <Lock className="w-4 h-4 text-secondary shrink-0 mt-0.5" />
              <div>
                <span className="font-bold text-foreground">%10 Komisyon & Escrow Güvencesi: </span>
                Tüm ödemeleriniz etkinlik başarıyla tamamlanana kadar güvenli havuz hesabında korunur.
              </div>
            </div>
          </div>
        </div>
      </main>

      <MobileBottomNav />
    </div>
  );
}
