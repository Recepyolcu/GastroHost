import * as React from "react"
import { Star, ArrowRight } from "lucide-react"
import { Card } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"

const CHEFS = [
  {
    id: "julian",
    name: "Chef Julian",
    price: "$150/person",
    rating: "4.9",
    description: "Master of contemporary French cuisine with global influences.",
    tags: ["French", "Fine Dining"],
    image:
      "https://lh3.googleusercontent.com/aida-public/AB6AXuBZ39tPphYle75Gmb_6AjN9N3Z-66K_iukAW9tqVL7Gvj-M1QjUM5jbY0VtG4Qb2FKmM8YyL6sAdcl9tDWO0IbmiUezB7Q2u4DngEr_sjhOQKmL6MN0XgCF4uRygDK_xMQKt29dslAEAK2j3xcT543wQZ_dDD9oc7hYygS9QN2KC9WxaeYEUk9zCJXaB5Lov9WCtRpFlaFSEs0-YpngYnmp4cKFYZ04BdJLAatycv9bs_LAbzWprbbq",
  },
  {
    id: "elena",
    name: "Chef Elena",
    price: "$120/person",
    rating: "4.8",
    description: "Authentic Italian heritage meets modern culinary techniques.",
    tags: ["Italian", "Rustic"],
    image:
      "https://lh3.googleusercontent.com/aida-public/AB6AXuChn-7FZZhW2-A3ZcBIy-XJfS_u32bim9mUqpimzSY-VOLTfHcAealsuuCTWRH7Tx_BbBSRdyc6rpO8HEUYTUHikNx-biLNWFDtXWR66fAhyO6V1JDFk_GmH3l274X67WAEXc2uzZkvqZ_yig1YVI6ZaUqCioJwLQN1hDUqWTPzV212eSPclZ2cZHGDCpjQLl23vkuvC3duxxx4y8_BXCHS5aKRO-e2AbBgjQQhINV-omXI5c8N1Mbz",
  },
  {
    id: "kenji",
    name: "Chef Kenji",
    price: "$180/person",
    rating: "5.0",
    description: "Innovative Japanese fusion omakase experiences at home.",
    tags: ["Japanese", "Omakase"],
    image:
      "https://lh3.googleusercontent.com/aida-public/AB6AXuDhu3jG7be0f_mX-3wz0kjL1snbVjZcWRd_yZtPOzSTaMwcQfg0uI_WDczXIG6YvKfDcK6smvcQbcmSQC9HiVG0Y8GxsNtiqzavDofeoJJk5MEfr3BELuClBAgXyFkt18pAHYWBOkrGijVmGTs0hjb3snV2PFPBwQTmIu1iIRH0r4tqNvrzFG8A1yx56-ycrkppZrE6Az3rCWr0d8i9RKMkNdAkUnnjhqEzdQpEyzvPgfrsY9o6zrcZ",
  },
]

export function RecommendedChefs() {
  return (
    <section className="w-full">
      {/* Section Header */}
      <div className="flex items-end justify-between mb-8">
        <div>
          <h2 className="font-serif text-2xl md:text-3xl font-bold tracking-tight text-foreground">
            Recommended Chefs for You
          </h2>
          <p className="text-sm text-muted-foreground mt-1">
            Top-rated culinary talent available for private bookings
          </p>
        </div>
        
        <button className="text-secondary font-semibold text-sm hover:underline flex items-center gap-1.5 transition-all">
          See all <ArrowRight className="w-4 h-4" />
        </button>
      </div>

      {/* Chefs Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {CHEFS.map((chef) => (
          <Card
            key={chef.id}
            className="group cursor-pointer hover:-translate-y-1 transition-all duration-300 border border-border/60 bg-card overflow-hidden"
          >
            {/* Image & Rating */}
            <div className="relative h-56 w-full overflow-hidden">
              <img
                src={chef.image}
                alt={chef.name}
                className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
              />
              <div className="absolute top-4 right-4 bg-background/90 backdrop-blur-md px-2.5 py-1 rounded-full flex items-center gap-1 shadow-sm">
                <Star className="w-3.5 h-3.5 fill-secondary text-secondary" />
                <span className="text-xs font-bold text-foreground">
                  {chef.rating}
                </span>
              </div>
            </div>

            {/* Card Content */}
            <div className="p-6 flex flex-col gap-4">
              <div className="flex justify-between items-start">
                <h3 className="font-serif text-xl font-bold text-foreground">
                  {chef.name}
                </h3>
                <span className="font-bold text-secondary text-sm">
                  {chef.price}
                </span>
              </div>

              <p className="text-sm text-muted-foreground line-clamp-2 leading-relaxed">
                {chef.description}
              </p>

              {/* Tags */}
              <div className="flex flex-wrap gap-2">
                {chef.tags.map((tag) => (
                  <Badge key={tag} variant="outline" className="text-xs font-normal">
                    {tag}
                  </Badge>
                ))}
              </div>

              {/* Action Button */}
              <Button variant="outline" className="w-full mt-2 font-medium">
                View Menu
              </Button>
            </div>
          </Card>
        ))}
      </div>
    </section>
  )
}
