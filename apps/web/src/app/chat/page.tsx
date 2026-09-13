import * as React from "react"
import Link from "next/link"
import { ArrowLeft, Send, Paperclip, CheckCircle2 } from "lucide-react"
import { Header } from "@/components/home/Header"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"

export default function ChatPage() {
  return (
    <div className="min-h-screen bg-background text-foreground antialiased pb-24 md:pb-12">
      <Header />

      <main className="pt-24 md:pt-32 px-6 max-w-4xl mx-auto w-full">
        {/* Navigation */}
        <div className="mb-6 flex items-center justify-between border-b border-border pb-4">
          <Link
            href="/tracker"
            className="flex items-center gap-2 text-sm font-semibold text-foreground hover:opacity-80 transition-opacity"
          >
            <ArrowLeft className="w-4 h-4" /> Back to Event Tracker
          </Link>
          <div className="flex items-center gap-2 text-xs font-bold text-secondary">
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" /> Active Event #b_demo_101
          </div>
        </div>

        {/* Chat Window Box */}
        <div className="bg-card border border-border rounded-2xl shadow-sm overflow-hidden flex flex-col h-[550px]">
          {/* Top Bar */}
          <div className="p-4 border-b border-border flex items-center justify-between bg-muted/30">
            <div className="flex items-center gap-3">
              <img
                src="https://lh3.googleusercontent.com/aida-public/AB6AXuCONoMmOXp0IjymBppcR4QkB6xr80XfagXEBCa0yI1Zt4NWfpJb6dPtzzSmAeUJCZ0UEdd9SEP-anJt2rq_REq4HHH3-K8902WrCKTp-oJluokeNMEJ8w5jKPmGBUZtB0bF9sTCTsBrvbCy2HVMAgcS2n4DSFhUG_gDEO1kbjiiDRKcw16uXYIwjsQE1rioTL1bVJW-635g42PTmwpQTKvuOc7jB-TrTegTDa_K8FhG5mF0rMFZXsHr"
                alt="Chef Marco"
                className="w-10 h-10 rounded-full object-cover"
              />
              <div>
                <div className="font-bold text-sm">Chef Marco</div>
                <div className="text-xs text-muted-foreground">Tuscan Fine Dining Specialist</div>
              </div>
            </div>
            <Button variant="outline" size="sm" className="rounded-full text-xs">Call Chef</Button>
          </div>

          {/* Messages Area */}
          <div className="flex-1 p-6 overflow-y-auto space-y-4">
            <div className="flex justify-start">
              <div className="bg-muted p-4 rounded-2xl max-w-md text-sm">
                Hello! I am preparing the fresh ingredients for your Truffle Experience tonight.
                <div className="text-[10px] text-muted-foreground mt-1 text-right">6:15 PM</div>
              </div>
            </div>

            <div className="flex justify-end">
              <div className="bg-primary text-primary-foreground p-4 rounded-2xl max-w-md text-sm">
                Great! Looking forward to it. We have a gluten-free guest joining us.
                <div className="text-[10px] text-primary-foreground/70 mt-1 text-right">6:18 PM</div>
              </div>
            </div>

            <div className="flex justify-start">
              <div className="bg-muted p-4 rounded-2xl max-w-md text-sm">
                Noted! I have sourced gluten-free handmade pasta dough specifically for them.
                <div className="text-[10px] text-muted-foreground mt-1 text-right">6:20 PM</div>
              </div>
            </div>
          </div>

          {/* Input Footer */}
          <div className="p-4 border-t border-border flex items-center gap-3 bg-card">
            <button className="p-2 text-muted-foreground hover:text-foreground">
              <Paperclip className="w-5 h-5" />
            </button>
            <Input placeholder="Type a message to Chef Marco..." className="flex-1" />
            <Button size="icon" className="rounded-full">
              <Send className="w-4 h-4" />
            </Button>
          </div>
        </div>
      </main>
    </div>
  )
}
