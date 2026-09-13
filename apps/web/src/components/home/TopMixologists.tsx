import * as React from "react"
import { Star, ArrowRight } from "lucide-react"
import { Card } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"

const MIXOLOGISTS = [
  {
    id: "marcus",
    name: "Marcus T.",
    rate: "$80/hr",
    rating: "4.9",
    tag: "Craft Cocktails",
    image:
      "https://lh3.googleusercontent.com/aida-public/AB6AXuDaVyI-CnIxT8YodSe6yue9G2LBJOi4QhgNlNMPJnjuAr-94xAgbuWyK3sO69pqU0pZHXmZX3vx0-EvNW9DOg84ESyCgW7FSvqZDa2zT8N4D6ipCIfxDraqPiYrQDxbGldcRLyepDXtlsaxJ4xaUgVwlylXd6xBYGqGQPijq1y7LRa8dlusjK03lBDWKMLyvPIZ1WzmLyhaoq4u5QlrvOJ1Do_iiFI3x3_Tyzf3RZvv4ClF9Vfr6xTh",
  },
  {
    id: "sarah",
    name: "Sarah W.",
    rate: "$75/hr",
    rating: "4.8",
    tag: "Botanical & Gin",
    image:
      "https://lh3.googleusercontent.com/aida-public/AB6AXuBtbnFtqWZqebz3aN6uXggy_L92XIqGpYBbUwJXpBl5iR7wMp8iQoVuhbdHKaDSAlgm74p4NFY_b7XSgAoOfC0k3MnqyQjE_Mk9KnlNYzz91w-ekMJ3n6pa3BmcB_FqEwCQjnOt7H7iaydg1DS2tUH6rhgh4mduKjJPxN_SgVwyHOtAt15ibC97srEOcwj2_Uqv4ckKMpAlEZ8QoGs4xrqljiXo_TrRIv_62z5EvnNPPc4bDZX7xqEQ",
  },
]

export function TopMixologists() {
  return (
    <section className="w-full">
      {/* Section Header */}
      <div className="flex items-end justify-between mb-8">
        <div>
          <h2 className="font-serif text-2xl md:text-3xl font-bold tracking-tight text-foreground">
            Top Rated Mixologists
          </h2>
          <p className="text-sm text-muted-foreground mt-1">
            Bespoke cocktail and beverage specialists for your gatherings
          </p>
        </div>

        <button className="text-secondary font-semibold text-sm hover:underline flex items-center gap-1.5 transition-all">
          See all <ArrowRight className="w-4 h-4" />
        </button>
      </div>

      {/* Mixologists Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {MIXOLOGISTS.map((mix) => (
          <Card
            key={mix.id}
            className="flex flex-row items-center p-6 gap-6 group cursor-pointer hover:-translate-y-1 transition-all duration-300 border border-border/60 bg-card"
          >
            {/* Avatar Image */}
            <img
              src={mix.image}
              alt={mix.name}
              className="w-24 h-24 rounded-xl object-cover shrink-0"
            />

            {/* Content */}
            <div className="flex-1 flex flex-col justify-between gap-2">
              <div className="flex justify-between items-start">
                <h3 className="font-serif text-xl font-bold text-foreground">
                  {mix.name}
                </h3>
                <div className="flex items-center gap-1">
                  <Star className="w-3.5 h-3.5 fill-secondary text-secondary" />
                  <span className="text-xs font-bold text-foreground">
                    {mix.rating}
                  </span>
                </div>
              </div>

              <div>
                <Badge variant="outline" className="text-xs font-normal">
                  {mix.tag}
                </Badge>
              </div>

              <div className="flex justify-between items-center mt-2">
                <span className="font-bold text-secondary text-base">
                  {mix.rate}
                </span>
                <Button size="sm" variant="outline" className="px-4">
                  Book
                </Button>
              </div>
            </div>
          </Card>
        ))}
      </div>
    </section>
  )
}
