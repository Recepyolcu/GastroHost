"use client";

import * as React from "react";
import { cn } from "@/lib/utils";
import { useAuth } from "@/lib/auth-context";
import { Sparkles, ChefHat, Wine, Utensils, Fish, Flame, Leaf } from "lucide-react";

const CATEGORIES = [
  { id: "all", label: "Tümü", icon: Sparkles },
  { id: "chef", label: "Özel Şefler", icon: ChefHat },
  { id: "bartender", label: "Barmen & Miksolojist", icon: Wine },
  { id: "İtalyan", label: "İtalyan & Fine Dining", icon: Utensils },
  { id: "Akdeniz", label: "Akdeniz & Deniz Ürünleri", icon: Fish },
  { id: "Anadolu", label: "Modern Anadolu & Ateş", icon: Flame },
  { id: "Glutensiz", label: "Glutensiz & Vegan", icon: Leaf },
];

export function CategoryScroll() {
  const { activeCategory, setActiveCategory } = useAuth();

  return (
    <section className="w-full">
      <div className="flex overflow-x-auto gap-2.5 hide-scrollbar snap-x snap-mandatory py-2">
        {CATEGORIES.map((cat) => {
          const Icon = cat.icon;
          const isActive = activeCategory === cat.id;
          return (
            <button
              key={cat.id}
              onClick={() => setActiveCategory(cat.id)}
              className={cn(
                "snap-start shrink-0 px-5 py-2.5 rounded-full font-semibold text-xs md:text-sm transition-all active:scale-95 duration-200 border flex items-center gap-2 cursor-pointer",
                isActive
                  ? "bg-primary text-primary-foreground border-primary shadow-md"
                  : "bg-muted/50 text-foreground border-border hover:bg-muted"
              )}
            >
              <Icon className={cn("w-4 h-4", isActive ? "text-secondary" : "text-muted-foreground")} />
              <span>{cat.label}</span>
            </button>
          );
        })}
      </div>
    </section>
  );
}
