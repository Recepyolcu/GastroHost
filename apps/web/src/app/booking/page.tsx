import * as React from "react"
import Link from "next/link"
import { ArrowLeft, Calendar, ShieldCheck, ChefHat, ShoppingBag, Check } from "lucide-react"
import { Header } from "@/components/home/Header"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"

export default function BookingPage() {
  return (
    <div className="min-h-screen bg-background text-foreground antialiased pb-24 md:pb-12">
      <Header />

      <main className="pt-24 md:pt-32 px-6 md:px-12 max-w-5xl mx-auto w-full">
        {/* Navigation */}
        <div className="mb-8">
          <Link
            href="/chef/1"
            className="flex items-center gap-2 text-sm font-semibold text-foreground hover:opacity-80 transition-opacity mb-4"
          >
            <ArrowLeft className="w-4 h-4" /> Back to Chef Details
          </Link>
          <h1 className="font-serif text-3xl md:text-4xl font-bold">
            Booking & Escrow Payment
          </h1>
          <p className="text-sm text-muted-foreground mt-1">
            Complete your reservation securely with GastroHost Escrow Protection.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-12 gap-8">
          {/* Left Column: Booking Form & Checklist */}
          <div className="md:col-span-7 space-y-8">
            {/* Date & Time */}
            <div className="bg-card border border-border p-6 rounded-2xl shadow-sm">
              <h2 className="font-bold text-lg mb-4 flex items-center gap-2">
                <Calendar className="w-5 h-5 text-secondary" /> Date & Time
              </h2>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div className="border border-border p-3 rounded-xl">
                  <div className="text-xs uppercase text-muted-foreground font-bold">Event Date</div>
                  <div className="font-semibold text-sm mt-1">Saturday, Oct 24, 2026</div>
                </div>
                <div className="border border-border p-3 rounded-xl">
                  <div className="text-xs uppercase text-muted-foreground font-bold">Start Time</div>
                  <div className="font-semibold text-sm mt-1">7:30 PM</div>
                </div>
              </div>
            </div>

            {/* Kitchen Requirements Check */}
            <div className="bg-card border border-border p-6 rounded-2xl shadow-sm">
              <h2 className="font-bold text-lg mb-2 flex items-center gap-2">
                Kitchen Check
              </h2>
              <p className="text-sm text-muted-foreground mb-4">
                Confirm your kitchen has the required equipment for Chef Marco's menu.
              </p>
              <div className="space-y-3">
                <label className="flex items-center gap-3 cursor-pointer">
                  <input type="checkbox" defaultChecked className="w-4 h-4 accent-secondary" />
                  <span className="text-sm font-medium">4-burner stove operating properly</span>
                </label>
                <label className="flex items-center gap-3 cursor-pointer">
                  <input type="checkbox" defaultChecked className="w-4 h-4 accent-secondary" />
                  <span className="text-sm font-medium">Working oven for roasting</span>
                </label>
                <label className="flex items-center gap-3 cursor-pointer">
                  <input type="checkbox" defaultChecked className="w-4 h-4 accent-secondary" />
                  <span className="text-sm font-medium">Blender or food processor</span>
                </label>
              </div>
            </div>

            {/* Ingredients Option */}
            <div className="bg-card border border-border p-6 rounded-2xl shadow-sm">
              <h2 className="font-bold text-lg mb-2 flex items-center gap-2">
                <ShoppingBag className="w-5 h-5 text-secondary" /> Ingredients & Sourcing
              </h2>
              <p className="text-sm text-muted-foreground mb-4">
                How would you like ingredients to be handled?
              </p>
              <div className="border border-secondary bg-secondary/5 p-4 rounded-xl flex items-center justify-between">
                <div>
                  <div className="font-bold text-sm">Chef Sourced (Recommended)</div>
                  <div className="text-xs text-muted-foreground">Chef purchases farm-fresh organic ingredients morning of event.</div>
                </div>
                <Badge variant="secondary">Included</Badge>
              </div>
            </div>
          </div>

          {/* Right Column: Escrow Payment Summary */}
          <div className="md:col-span-5">
            <div className="bg-card border border-border p-6 rounded-2xl shadow-md sticky top-32 space-y-6">
              <h2 className="font-serif text-xl font-bold pb-4 border-b border-border">
                Payment Summary
              </h2>

              <div className="space-y-3 text-sm">
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Truffle Experience ($120 x 4 guests)</span>
                  <span className="font-semibold">$480.00</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Chef Sourcing & Prep Fee</span>
                  <span className="font-semibold">$60.00</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Service Fee</span>
                  <span className="font-semibold">$35.00</span>
                </div>
                <div className="border-t border-border pt-3 flex justify-between font-bold text-base">
                  <span>Total Amount</span>
                  <span className="text-secondary">$575.00</span>
                </div>
              </div>

              {/* Escrow Protection Banner */}
              <div className="bg-muted p-4 rounded-xl flex items-start gap-3 text-xs text-muted-foreground">
                <ShieldCheck className="w-5 h-5 text-secondary shrink-0 mt-0.5" />
                <div>
                  <div className="font-bold text-foreground mb-0.5">GastroHost Escrow Guarantee</div>
                  Your funds are held securely in escrow and only released to the chef after your event is successfully completed.
                </div>
              </div>

              <Link href="/tracker">
                <Button className="w-full py-6 text-base font-bold rounded-xl mt-4">
                  Pay $575.00 with Escrow
                </Button>
              </Link>
            </div>
          </div>
        </div>
      </main>
    </div>
  )
}
