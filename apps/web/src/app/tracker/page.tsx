import * as React from "react"
import Link from "next/link"
import { ArrowLeft, CheckCircle2, MapPin, MessageSquare, Receipt, Clock } from "lucide-react"
import { Header } from "@/components/home/Header"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"

export default function TrackerPage() {
  return (
    <div className="min-h-screen bg-background text-foreground antialiased pb-24 md:pb-12">
      <Header />

      <main className="pt-24 md:pt-32 px-6 md:px-12 max-w-6xl mx-auto w-full">
        {/* Event Title Header */}
        <div className="mb-8 border-b border-border pb-6">
          <div className="flex items-center gap-2 text-xs font-bold text-secondary uppercase tracking-widest mb-1">
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" /> Live Event Active
          </div>
          <h1 className="font-serif text-3xl md:text-4xl font-bold">
            Tonight's Event with Chef Marco
          </h1>
          <p className="text-sm text-muted-foreground mt-1">
            Tuscan Truffle Experience • Starting at 7:30 PM
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-12 gap-8">
          {/* Left Column: Live Timeline & Map */}
          <div className="md:col-span-7 space-y-8">
            {/* Status Timeline */}
            <div className="bg-card border border-border p-6 rounded-2xl shadow-sm">
              <h2 className="font-serif text-xl font-bold mb-6">Live Status</h2>
              <div className="relative pl-6 space-y-8 border-l-2 border-border ml-2">
                {/* Step 1: Completed */}
                <div className="relative">
                  <div className="absolute -left-[31px] top-0 w-6 h-6 rounded-full bg-primary text-primary-foreground flex items-center justify-center text-xs font-bold">
                    <CheckCircle2 className="w-4 h-4 text-emerald-400" />
                  </div>
                  <h3 className="font-bold text-base text-foreground">Ingredient Sourcing</h3>
                  <p className="text-sm text-muted-foreground">Chef completed sourcing Alba truffles & fresh pasta ingredients.</p>
                </div>

                {/* Step 2: In Progress */}
                <div className="relative">
                  <div className="absolute -left-[31px] top-0 w-6 h-6 rounded-full bg-secondary text-secondary-foreground flex items-center justify-center text-xs font-bold animate-bounce">
                    <Clock className="w-3.5 h-3.5" />
                  </div>
                  <h3 className="font-bold text-base text-secondary">Chef in Transit</h3>
                  <p className="text-sm text-muted-foreground">Arriving in approximately 15 minutes.</p>
                </div>

                {/* Step 3: Upcoming */}
                <div className="relative opacity-50">
                  <div className="absolute -left-[31px] top-0 w-6 h-6 rounded-full bg-muted border border-border" />
                  <h3 className="font-bold text-base text-foreground">Preparation Started</h3>
                </div>

                {/* Step 4: Upcoming */}
                <div className="relative opacity-50">
                  <div className="absolute -left-[31px] top-0 w-6 h-6 rounded-full bg-muted border border-border" />
                  <h3 className="font-bold text-base text-foreground">Service Live</h3>
                </div>
              </div>
            </div>

            {/* Map View */}
            <div className="relative h-72 rounded-2xl overflow-hidden border border-border shadow-sm">
              <img
                src="https://lh3.googleusercontent.com/aida-public/AB6AXuBVy2kw2xBFlyCArG9akCtDTiZHJUx0XGlWhoRI--ZD4OFS2nju_x0WMPCPdZ2H9LrmAVu1Lko9AIOOCwidSXvD00bUkTI9Z9vKQe2MRCTEPmp8i8-eZ7XvNb2wRTiH-_vErWBRcAGQTn7ruY3yfn78O1z0LEyW30e85gDWFYAD8AZ9SdITykQMlqloiJQt93KZsva5AXFOZjI5NSNZcc5zJhCnQgUSViTtxb5Oxel9lWz2qbZETfcW"
                alt="Map view"
                className="w-full h-full object-cover"
              />
              <div className="absolute bottom-4 right-4">
                <Button className="flex items-center gap-2 shadow-lg rounded-full">
                  <MessageSquare className="w-4 h-4" /> Chat with Chef
                </Button>
              </div>
            </div>
          </div>

          {/* Right Column: Procurement Receipt */}
          <div className="md:col-span-5">
            <div className="bg-card border border-border p-6 rounded-2xl shadow-sm space-y-6">
              <div className="flex items-center gap-2 pb-4 border-b border-border">
                <Receipt className="w-5 h-5 text-secondary" />
                <h2 className="font-serif text-xl font-bold">Procurement Receipt</h2>
              </div>
              <p className="text-xs text-muted-foreground">
                Sourced fresh this morning specifically for your menu.
              </p>

              <div className="space-y-3 text-sm">
                <div className="flex justify-between">
                  <span className="font-medium">Alba White Truffles</span>
                  <span className="text-muted-foreground">2 oz</span>
                </div>
                <div className="flex justify-between">
                  <span className="font-medium">Hand-milled 00 Flour</span>
                  <span className="text-muted-foreground">500g</span>
                </div>
                <div className="flex justify-between">
                  <span className="font-medium">Aged Parmigiano-Reggiano</span>
                  <span className="text-muted-foreground">1 wedge</span>
                </div>
                <div className="flex justify-between">
                  <span className="font-medium">Farm Fresh Organic Eggs</span>
                  <span className="text-muted-foreground">1 dz</span>
                </div>
                <div className="flex justify-between">
                  <span className="font-medium">Chianina Beef Tenderloin</span>
                  <span className="text-muted-foreground">32 oz</span>
                </div>
              </div>

              <div className="pt-4 border-t border-dashed border-border flex justify-between items-center text-sm font-bold text-emerald-600">
                <span>Sourcing Verified</span>
                <CheckCircle2 className="w-4 h-4" />
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  )
}
