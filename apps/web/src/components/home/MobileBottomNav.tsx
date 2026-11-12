"use client";

import * as React from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { Compass, Activity, MessageSquare, ChefHat, ShieldCheck, User } from "lucide-react";

export function MobileBottomNav() {
  const pathname = usePathname();

  const items = [
    { href: "/", label: "Keşfet", icon: Compass },
    { href: "/tracker", label: "Takip", icon: Activity },
    { href: "/chat", label: "Sohbet", icon: MessageSquare },
    { href: "/chef-dashboard", label: "Şef Panel", icon: ChefHat },
    { href: "/admin", label: "Admin", icon: ShieldCheck },
    { href: "/profile", label: "Profil", icon: User },
  ];

  return (
    <nav className="fixed bottom-0 left-0 w-full z-50 bg-background/95 backdrop-blur-lg border-t border-border lg:hidden shadow-lg">
      <div className="flex justify-around items-center h-16 px-2">
        {items.map((item) => {
          const Icon = item.icon;
          const isActive =
            item.href === "/"
              ? pathname === "/"
              : pathname.startsWith(item.href);

          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex flex-col items-center justify-center gap-1 transition-all px-2 py-1 rounded-xl ${
                isActive
                  ? "text-secondary font-bold"
                  : "text-muted-foreground hover:text-foreground"
              }`}
            >
              <Icon className="w-5 h-5" />
              <span className="text-[10px]">{item.label}</span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
