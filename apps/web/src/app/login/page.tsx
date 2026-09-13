"use client"

import * as React from "react"
import Link from "next/link"
import { Header } from "@/components/home/Header"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"

export default function LoginPage() {
  const [role, setRole] = React.useState<"customer" | "chef">("customer")

  return (
    <div className="min-h-screen bg-background text-foreground antialiased pb-24 md:pb-12">
      <Header />

      <main className="pt-24 md:pt-32 px-6 max-w-md mx-auto w-full">
        {/* Brand Header */}
        <div className="text-center mb-8">
          <h1 className="font-serif text-3xl font-bold mb-2">GastroHost</h1>
          <p className="text-sm text-muted-foreground">Sign in or create an account</p>
        </div>

        {/* Role Toggle Tabs */}
        <div className="flex border-b border-border mb-6">
          <button
            onClick={() => setRole("customer")}
            className={`flex-1 py-3 text-center text-sm font-semibold transition-colors border-b-2 ${
              role === "customer"
                ? "border-secondary text-foreground"
                : "border-transparent text-muted-foreground hover:text-foreground"
            }`}
          >
            Customer
          </button>
          <button
            onClick={() => setRole("chef")}
            className={`flex-1 py-3 text-center text-sm font-semibold transition-colors border-b-2 ${
              role === "chef"
                ? "border-secondary text-foreground"
                : "border-transparent text-muted-foreground hover:text-foreground"
            }`}
          >
            Chef
          </button>
        </div>

        {/* Card Form */}
        <div className="bg-card border border-border p-6 rounded-2xl shadow-sm space-y-5">
          <div>
            <label className="text-xs font-bold uppercase text-muted-foreground block mb-2">
              Email or Phone Number
            </label>
            <Input placeholder="name@example.com" />
          </div>

          <div>
            <label className="text-xs font-bold uppercase text-muted-foreground block mb-2">
              Password
            </label>
            <Input type="password" placeholder="••••••••" />
          </div>

          <div className="flex justify-between items-center text-xs">
            <label className="flex items-center gap-2 cursor-pointer">
              <input type="checkbox" className="rounded accent-secondary" />
              <span>Remember me</span>
            </label>
            <a href="#" className="text-secondary font-semibold hover:underline">Forgot password?</a>
          </div>

          <Link href={role === "chef" ? "/chef-dashboard" : "/"}>
            <Button className="w-full py-6 text-base font-bold rounded-xl mt-4">
              Continue
            </Button>
          </Link>
        </div>
      </main>
    </div>
  )
}
