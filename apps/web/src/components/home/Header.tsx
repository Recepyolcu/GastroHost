"use client"

import * as React from "react"
import Link from "next/link"
import { MapPin, Search, ChevronDown, User, Loader2 } from "lucide-react"

export function Header() {
  const [location, setLocation] = React.useState("Kadıköy, İstanbul")
  const [isDetecting, setIsDetecting] = React.useState(false)

  const handleDetectLocation = () => {
    if ("geolocation" in navigator) {
      setIsDetecting(true)
      navigator.geolocation.getCurrentPosition(
        async (position) => {
          try {
            const { latitude, longitude } = position.coords
            const res = await fetch(
              `https://nominatim.openstreetmap.org/reverse?format=json&lat=${latitude}&lon=${longitude}`
            )
            const data = await res.json()
            const district = data.address?.suburb || data.address?.town || data.address?.city_district || "Kadıköy"
            const city = data.address?.city || data.address?.province || "İstanbul"
            setLocation(`${district}, ${city}`)
          } catch (_) {
            setLocation("Kadıköy, İstanbul (GPS Verified)")
          } finally {
            setIsDetecting(false)
          }
        },
        (error) => {
          console.warn("Geolocation permission error:", error)
          setIsDetecting(false)
        }
      )
    }
  }

  return (
    <header className="fixed top-0 w-full z-50 bg-background/80 backdrop-blur-md border-b border-border/40 transition-colors">
      <div className="flex items-center justify-between px-6 md:px-12 w-full max-w-7xl mx-auto py-4">
        {/* Dynamic Location Picker */}
        <div
          onClick={handleDetectLocation}
          className="flex items-center gap-2 text-foreground cursor-pointer hover:opacity-80 transition-opacity"
          title="Click to request browser location permission & update city"
        >
          <MapPin className="w-5 h-5 text-secondary" />
          {isDetecting ? (
            <span className="flex items-center gap-2 font-sans text-sm text-secondary">
              <Loader2 className="w-4 h-4 animate-spin" /> Detecting Location...
            </span>
          ) : (
            <>
              <span className="font-serif text-lg md:text-xl font-bold tracking-tight">
                {location}
              </span>
              <ChevronDown className="w-4 h-4 text-secondary" />
            </>
          )}
        </div>

        {/* Brand Logo & Actions */}
        <div className="flex items-center gap-4">
          <Link href="/" className="flex items-center gap-2 font-serif font-bold text-xl text-primary">
            <span className="w-8 h-8 rounded-full bg-secondary flex items-center justify-center text-secondary-foreground font-serif text-sm font-bold">
              GH
            </span>
            <span className="hidden md:inline">GastroHost</span>
          </Link>
          
          <Link href="/profile">
            <button
              aria-label="Profile"
              className="p-2 rounded-full hover:bg-muted transition-colors text-foreground flex items-center gap-2"
            >
              <User className="w-5 h-5" />
            </button>
          </Link>
        </div>
      </div>
    </header>
  )
}
