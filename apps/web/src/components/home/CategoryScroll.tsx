"use client"

import * as React from "react"
import { cn } from "@/lib/utils"

const CATEGORIES = [
  { id: "chefs", label: "Private Chefs" },
  { id: "mixologists", label: "Mixologists" },
  { id: "waitstaff", label: "Waitstaff" },
  { id: "sommelier", label: "Sommelier" },
]

export function CategoryScroll() {
  const [activeCategory, setActiveCategory] = React.useState("chefs")

  return (
    <section className="w-full">
      <div className="flex overflow-x-auto gap-3 hide-scrollbar snap-x snap-mandatory py-2">
        {CATEGORIES.map((cat) => {
          const isActive = activeCategory === cat.id
          return (
            <button
              key={cat.id}
              onClick={() => setActiveCategory(cat.id)}
              className={cn(
                "snap-start shrink-0 px-6 py-2.5 rounded-full font-medium text-sm transition-all active:scale-95 duration-200 border",
                isActive
                  ? "bg-primary text-primary-foreground border-primary shadow-md"
                  : "bg-muted/50 text-foreground border-border hover:bg-muted"
              )}
            >
              {cat.label}
            </button>
          )
        })}
      </div>
    </section>
  )
}
