import * as React from "react"
import Link from "next/link"
import { ArrowLeft, ShieldCheck, MapPin, CreditCard, Bell, Heart, Utensils, CheckCircle2, ChevronRight, Award, LogOut, Flame } from "lucide-react"
import { Header } from "@/components/home/Header"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"

export default function ProfilePage() {
  return (
    <div className="min-h-screen bg-background text-foreground antialiased pb-24 md:pb-12">
      <Header />

      <main className="pt-24 md:pt-32 px-6 md:px-12 max-w-5xl mx-auto w-full">
        {/* Navigation */}
        <div className="flex items-center justify-between mb-6">
          <Link
            href="/"
            className="flex items-center gap-2 text-sm font-semibold text-foreground hover:opacity-80 transition-opacity"
          >
            <ArrowLeft className="w-4 h-4" /> Back to Explore
          </Link>
          <Button variant="outline" size="sm" className="gap-2 rounded-full">
            <Flame className="w-4 h-4 text-secondary" /> Switch to Chef Mode
          </Button>
        </div>

        {/* 1. Header Profile Card */}
        <div className="bg-card border border-border p-6 md:p-8 rounded-2xl shadow-sm mb-8">
          <div className="flex flex-col md:flex-row items-center md:items-start justify-between gap-6 border-b border-border pb-6">
            <div className="flex flex-col md:flex-row items-center md:items-start gap-4 text-center md:text-left">
              <div className="w-20 h-20 rounded-full bg-secondary/10 text-secondary border-2 border-secondary/30 flex items-center justify-center font-serif text-2xl font-bold">
                AY
              </div>
              <div>
                <div className="flex items-center justify-center md:justify-start gap-2">
                  <h1 className="font-serif text-2xl font-bold">Ahmet Yılmaz</h1>
                  <Badge variant="secondary" className="gap-1">
                    <Award className="w-3 h-3" /> VIP Gourmet
                  </Badge>
                </div>
                <p className="text-sm text-muted-foreground mt-1">ahmet.yilmaz@example.com • +90 532 123 45 67</p>
                <div className="flex items-center justify-center md:justify-start gap-2 text-xs text-muted-foreground mt-2">
                  <MapPin className="w-3.5 h-3.5 text-secondary" /> Kadıköy, İstanbul
                </div>
              </div>
            </div>
            <Button variant="outline" className="rounded-full">Edit Profile</Button>
          </div>

          {/* Stats Bar */}
          <div className="grid grid-cols-3 gap-4 pt-6 text-center">
            <div>
              <div className="font-serif text-2xl font-bold text-foreground">12</div>
              <div className="text-xs text-muted-foreground font-medium mt-0.5">Events Hosted</div>
            </div>
            <div className="border-x border-border">
              <div className="font-serif text-2xl font-bold text-foreground">8</div>
              <div className="text-xs text-muted-foreground font-medium mt-0.5">Saved Chefs</div>
            </div>
            <div>
              <div className="font-serif text-2xl font-bold text-secondary">1.450</div>
              <div className="text-xs text-muted-foreground font-medium mt-0.5">GastroPoints</div>
            </div>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-12 gap-8">
          {/* Left Column: Passport & Bookings */}
          <div className="md:col-span-7 space-y-8">
            {/* 2. Culinary & Allergy Passport */}
            <div className="bg-card border border-border p-6 rounded-2xl shadow-sm">
              <div className="flex items-center justify-between mb-4">
                <h2 className="font-serif text-xl font-bold flex items-center gap-2">
                  <Utensils className="w-5 h-5 text-secondary" /> Culinary & Allergy Passport
                </h2>
                <span className="text-xs font-semibold text-secondary hover:underline cursor-pointer">Update</span>
              </div>
              <p className="text-xs text-muted-foreground mb-4">
                Shared automatically with booking chefs to customize your menu safely.
              </p>

              <div className="space-y-4">
                <div>
                  <div className="text-xs font-bold uppercase text-muted-foreground mb-2">Dietary & Allergies</div>
                  <div className="flex flex-wrap gap-2">
                    <Badge variant="outline">Gluten-Free Option</Badge>
                    <Badge variant="outline">No Shellfish</Badge>
                    <Badge variant="outline">Lactose Tolerant</Badge>
                  </div>
                </div>

                <div>
                  <div className="text-xs font-bold uppercase text-muted-foreground mb-2">Cuisine Preferences</div>
                  <div className="flex flex-wrap gap-2">
                    <Badge variant="secondary">Italian Fine Dining</Badge>
                    <Badge variant="secondary">French Contemporary</Badge>
                    <Badge variant="secondary">Japanese Omakase</Badge>
                  </div>
                </div>

                <div>
                  <div className="text-xs font-bold uppercase text-muted-foreground mb-2">Home Kitchen Equipment</div>
                  <div className="flex flex-wrap gap-2">
                    <Badge variant="outline">4-Burner Stove</Badge>
                    <Badge variant="outline">Convection Oven</Badge>
                    <Badge variant="outline">Blender / Processor</Badge>
                  </div>
                </div>
              </div>
            </div>

            {/* 3. Recent Bookings */}
            <div className="bg-card border border-border p-6 rounded-2xl shadow-sm">
              <div className="flex items-center justify-between mb-4">
                <h2 className="font-serif text-xl font-bold">Upcoming & Recent Events</h2>
                <span className="text-xs font-semibold text-secondary hover:underline cursor-pointer">View All</span>
              </div>

              {/* Booking Item */}
              <div className="border border-border p-4 rounded-xl flex items-center justify-between hover:border-secondary transition-colors">
                <div>
                  <div className="flex items-center gap-2">
                    <span className="font-bold text-sm">Chef Marco</span>
                    <Badge variant="secondary" className="text-[10px]">Oct 24 • 7:30 PM</Badge>
                  </div>
                  <div className="text-xs text-muted-foreground mt-1">Tuscan Truffle Experience (4 Guests)</div>
                </div>
                <Link href="/tracker">
                  <Button size="sm" className="rounded-full text-xs">Live Tracker</Button>
                </Link>
              </div>
            </div>
          </div>

          {/* Right Column: Settings & Quick Links */}
          <div className="md:col-span-5 space-y-6">
            {/* Wallet & Payments */}
            <div className="bg-card border border-border p-6 rounded-2xl shadow-sm space-y-4">
              <h2 className="font-serif text-lg font-bold flex items-center gap-2">
                <CreditCard className="w-5 h-5 text-secondary" /> Wallet & Payments
              </h2>

              <div className="flex justify-between items-center p-3 bg-muted rounded-xl">
                <div>
                  <div className="text-xs text-muted-foreground font-medium">GastroWallet Escrow Balance</div>
                  <div className="font-serif text-xl font-bold text-foreground">₺0.00</div>
                </div>
                <Button variant="outline" size="sm" className="rounded-full">Top Up</Button>
              </div>

              <div className="space-y-2 text-sm">
                <div className="flex justify-between items-center p-2 rounded-lg hover:bg-muted/50 cursor-pointer">
                  <span className="font-medium">Saved Payment Cards</span>
                  <ChevronRight className="w-4 h-4 text-muted-foreground" />
                </div>
                <div className="flex justify-between items-center p-2 rounded-lg hover:bg-muted/50 cursor-pointer">
                  <span className="font-medium">Saved Addresses (Home, Villa)</span>
                  <ChevronRight className="w-4 h-4 text-muted-foreground" />
                </div>
              </div>
            </div>

            {/* Account Options */}
            <div className="bg-card border border-border p-6 rounded-2xl shadow-sm space-y-3 text-sm">
              <div className="flex justify-between items-center p-2 rounded-lg hover:bg-muted/50 cursor-pointer">
                <span className="font-medium">Notification Settings</span>
                <ChevronRight className="w-4 h-4 text-muted-foreground" />
              </div>
              <div className="flex justify-between items-center p-2 rounded-lg hover:bg-muted/50 cursor-pointer">
                <span className="font-medium">24/7 VIP Concierge Support</span>
                <ChevronRight className="w-4 h-4 text-muted-foreground" />
              </div>
              <div className="pt-3 border-t border-border flex items-center gap-2 text-destructive font-semibold cursor-pointer">
                <LogOut className="w-4 h-4" /> Log Out
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  )
}
