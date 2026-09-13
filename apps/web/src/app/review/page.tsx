"use client"

import * as React from "react"
import Link from "next/link"
import { ArrowLeft, Star, Camera, Check } from "lucide-react"
import { Header } from "@/components/home/Header"
import { Button } from "@/components/ui/button"

export default function ReviewPage() {
  const [rating, setRating] = React.useState(5)

  return (
    <div className="min-h-screen bg-background text-foreground antialiased pb-24 md:pb-12">
      <Header />

      <main className="pt-24 md:pt-32 px-6 max-w-xl mx-auto w-full">
        <div className="mb-6">
          <Link
            href="/profile"
            className="flex items-center gap-2 text-sm font-semibold text-foreground hover:opacity-80 transition-opacity mb-4"
          >
            <ArrowLeft className="w-4 h-4" /> Back to Profile
          </Link>
          <h1 className="font-serif text-3xl font-bold">Rate Your Experience</h1>
          <p className="text-sm text-muted-foreground mt-1">How was your event with Chef Marco?</p>
        </div>

        <div className="bg-card border border-border p-6 md:p-8 rounded-2xl shadow-sm space-y-6">
          {/* Star Selector */}
          <div className="flex justify-center gap-2">
            {[1, 2, 3, 4, 5].map((star) => (
              <button
                key={star}
                onClick={() => setRating(star)}
                className="p-2 transition-transform hover:scale-110"
              >
                <Star
                  className={`w-8 h-8 ${
                    star <= rating ? "fill-secondary text-secondary" : "text-muted-foreground/30"
                  }`}
                />
              </button>
            ))}
          </div>

          {/* Review Text */}
          <div>
            <label className="text-xs font-bold uppercase text-muted-foreground block mb-2">
              Your Feedback & Comments
            </label>
            <textarea
              rows={4}
              placeholder="Tell us about the dishes, presentation, and service..."
              className="w-full bg-transparent border border-border p-4 rounded-xl text-sm focus:outline-none focus:border-secondary"
            />
          </div>

          {/* Photo Upload */}
          <div className="border-2 border-dashed border-border p-6 rounded-xl text-center space-y-2 cursor-pointer hover:border-secondary transition-colors">
            <Camera className="w-6 h-6 text-muted-foreground mx-auto" />
            <div className="text-xs font-bold">Add Dish Photos</div>
            <div className="text-[11px] text-muted-foreground">Upload photos of the plated courses</div>
          </div>

          <Link href="/">
            <Button className="w-full py-6 text-base font-bold rounded-xl mt-4">
              Submit Review
            </Button>
          </Link>
        </div>
      </main>
    </div>
  )
}
