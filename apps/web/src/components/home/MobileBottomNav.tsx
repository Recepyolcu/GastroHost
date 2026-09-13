import * as React from "react"
import { Compass, Calendar, MessageSquare, User } from "lucide-react"

export function MobileBottomNav() {
  return (
    <nav className="fixed bottom-0 left-0 w-full z-50 bg-background/95 backdrop-blur-lg border-t border-border md:hidden shadow-lg">
      <div className="flex justify-around items-center h-16 px-4">
        {/* Explore (Active) */}
        <button className="flex flex-col items-center justify-center gap-1 text-primary font-bold transition-all">
          <Compass className="w-5 h-5 text-secondary" />
          <span className="text-[11px]">Explore</span>
        </button>

        {/* Bookings */}
        <button className="flex flex-col items-center justify-center gap-1 text-muted-foreground hover:text-foreground transition-all">
          <Calendar className="w-5 h-5" />
          <span className="text-[11px]">Bookings</span>
        </button>

        {/* Messages */}
        <button className="flex flex-col items-center justify-center gap-1 text-muted-foreground hover:text-foreground transition-all">
          <MessageSquare className="w-5 h-5" />
          <span className="text-[11px]">Messages</span>
        </button>

        {/* Profile */}
        <button className="flex flex-col items-center justify-center gap-1 text-muted-foreground hover:text-foreground transition-all">
          <User className="w-5 h-5" />
          <span className="text-[11px]">Profile</span>
        </button>
      </div>
    </nav>
  )
}
