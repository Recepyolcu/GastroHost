import * as React from "react"
import Link from "next/link"
import { ArrowLeft, Calendar, DollarSign, CheckCircle2, MessageSquare, Clock, Users } from "lucide-react"
import { Header } from "@/components/home/Header"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"

export default function ChefDashboardPage() {
  return (
    <div className="min-h-screen bg-background text-foreground antialiased pb-24 md:pb-12">
      <Header />

      <main className="pt-24 md:pt-32 px-6 md:px-12 max-w-6xl mx-auto w-full">
        {/* Title & Mode Switch */}
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-8">
          <div>
            <h1 className="font-serif text-3xl md:text-4xl font-bold">Chef Dashboard</h1>
            <p className="text-sm text-muted-foreground mt-1">Manage private dining requests & Escrow payouts.</p>
          </div>
          <Link href="/">
            <Button variant="outline" className="rounded-full gap-2">
              Switch to Customer Mode
            </Button>
          </Link>
        </div>

        {/* Stats Row */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-6 mb-8">
          <div className="bg-card border border-border p-6 rounded-2xl shadow-sm">
            <div className="text-xs uppercase text-muted-foreground font-bold">Escrow Net Earnings</div>
            <div className="font-serif text-3xl font-bold mt-2">$2,450.00</div>
          </div>
          <div className="bg-card border border-border p-6 rounded-2xl shadow-sm">
            <div className="text-xs uppercase text-muted-foreground font-bold">Pending Payouts</div>
            <div className="font-serif text-3xl font-bold text-secondary mt-2">$840.00</div>
          </div>
          <div className="bg-card border border-border p-6 rounded-2xl shadow-sm">
            <div className="text-xs uppercase text-muted-foreground font-bold">Completed Events</div>
            <div className="font-serif text-3xl font-bold mt-2">18 Events</div>
          </div>
        </div>

        {/* Booking Requests List */}
        <div className="space-y-6">
          <h2 className="font-serif text-2xl font-bold">Booking Requests</h2>

          {/* Request 1 */}
          <div className="bg-card border border-border p-6 rounded-2xl shadow-sm flex flex-col md:flex-row justify-between items-start md:items-center gap-6">
            <div className="space-y-2">
              <div className="flex items-center gap-3">
                <span className="font-bold text-lg">Ahmet Yılmaz</span>
                <Badge variant="secondary">$480.00 Net</Badge>
              </div>
              <p className="text-sm text-muted-foreground">Tuscan Truffle Experience • 6 Guests</p>
              <div className="flex items-center gap-2 text-xs text-muted-foreground">
                <Calendar className="w-3.5 h-3.5" /> Oct 24, 2026 • 7:30 PM
              </div>
              <div className="flex gap-2 mt-2">
                <Badge variant="outline">Gluten-Free Required</Badge>
                <Badge variant="outline">4-Burner Stove</Badge>
              </div>
            </div>

            <div className="flex items-center gap-3 w-full md:w-auto">
              <Button className="flex-1 md:flex-initial rounded-xl">Accept Request</Button>
              <Button variant="outline" className="rounded-xl">Decline</Button>
            </div>
          </div>

          {/* Request 2 */}
          <div className="bg-card border border-border p-6 rounded-2xl shadow-sm flex flex-col md:flex-row justify-between items-start md:items-center gap-6">
            <div className="space-y-2">
              <div className="flex items-center gap-3">
                <span className="font-bold text-lg">Zeynep Kaya</span>
                <Badge variant="secondary">$360.00 Net</Badge>
              </div>
              <p className="text-sm text-muted-foreground">Grand Tasting (5-Course) • 4 Guests</p>
              <div className="flex items-center gap-2 text-xs text-muted-foreground">
                <Calendar className="w-3.5 h-3.5" /> Oct 26, 2026 • 8:00 PM
              </div>
            </div>

            <div className="flex items-center gap-3 w-full md:w-auto">
              <Badge variant="outline" className="bg-emerald-500/10 text-emerald-600 border-emerald-500/30">
                Accepted & Scheduled
              </Badge>
              <Link href="/chat">
                <Button variant="outline" size="sm" className="rounded-full gap-2">
                  <MessageSquare className="w-4 h-4 text-secondary" /> Chat
                </Button>
              </Link>
            </div>
          </div>
        </div>
      </main>
    </div>
  )
}
