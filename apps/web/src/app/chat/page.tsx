"use client";

import * as React from "react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { ArrowLeft, Send, Image as ImageIcon, Loader2 } from "lucide-react";
import { Header } from "@/components/home/Header";
import { MobileBottomNav } from "@/components/home/MobileBottomNav";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { supabase } from "@/lib/supabase";
import { useAuth } from "@/lib/auth-context";

interface ChatMessageItem {
  id: string;
  booking_id: string;
  sender_id: string;
  sender_role: string;
  content: string;
  attachment_url?: string | null;
  created_at: string;
}

interface ChatBookingSummary {
  id: string;
  booking_code: string;
  customer_id: string;
  provider?: {
    id: string;
    title: string;
    user?: { id: string; full_name: string; avatar_url?: string };
  };
  customer?: {
    id: string;
    full_name: string;
  };
}

function ChatContent() {
  const searchParams = useSearchParams();
  const paramBookingId = searchParams.get("bookingId");
  const { userProfile } = useAuth();

  const [bookings, setBookings] = React.useState<ChatBookingSummary[]>([]);
  const [activeBookingId, setActiveBookingId] = React.useState<string>(paramBookingId || "");
  const [messages, setMessages] = React.useState<ChatMessageItem[]>([]);
  const [text, setText] = React.useState<string>("");
  const [sending, setSending] = React.useState<boolean>(false);
  const [loading, setLoading] = React.useState<boolean>(true);

  const loadBookings = React.useCallback(async () => {
    const { data } = await supabase
      .from("bookings")
      .select(
        `
        id,
        booking_code,
        customer_id,
        customer:profiles!bookings_customer_id_fkey(id, full_name),
        provider:provider_profiles!bookings_provider_id_fkey(
          id,
          title,
          user:profiles(id, full_name, avatar_url)
        )
      `
      )
      .order("created_at", { ascending: false });

    if (data && data.length > 0) {
      const list = data as unknown as ChatBookingSummary[];
      setBookings(list);
      if (!activeBookingId) {
        const match = list.find((b) => b.id === paramBookingId) || list[0];
        setActiveBookingId(match.id);
      }
    }
    setLoading(false);
  }, [activeBookingId, paramBookingId]);

  const loadMessages = React.useCallback(async (bId: string) => {
    if (!bId) return;
    const { data } = await supabase
      .from("messages")
      .select("*")
      .eq("booking_id", bId)
      .order("created_at", { ascending: true });
    if (data) {
      setMessages(data as unknown as ChatMessageItem[]);
    }
  }, []);

  React.useEffect(() => {
    loadBookings();
  }, [loadBookings]);

  React.useEffect(() => {
    if (!activeBookingId) return;
    loadMessages(activeBookingId);

    const channel = supabase
      .channel(`chat-room-${activeBookingId}`)
      .on(
        "postgres_changes",
        {
          event: "INSERT",
          schema: "public",
          table: "messages",
          filter: `booking_id=eq.${activeBookingId}`,
        },
        (payload) => {
          const newMsg = payload.new as ChatMessageItem;
          setMessages((prev) =>
            prev.some((m) => m.id === newMsg.id) ? prev : [...prev, newMsg]
          );
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [activeBookingId, loadMessages]);

  const currentBooking = bookings.find((b) => b.id === activeBookingId) || bookings[0];

  const handleSendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!text.trim() || !currentBooking) return;

    setSending(true);
    const senderId = userProfile?.id || currentBooking.customer_id;
    const senderRole =
      userProfile?.role === "chef" || userProfile?.role === "bartender"
        ? userProfile.role
        : "customer";

    try {
      const { data: inserted } = await supabase
        .from("messages")
        .insert({
          booking_id: currentBooking.id,
          sender_id: senderId,
          sender_role: senderRole,
          content: text.trim(),
          delivery_status: "sent",
        })
        .select("*")
        .single();

      if (inserted) {
        const msg = inserted as unknown as ChatMessageItem;
        setMessages((prev) => (prev.some((m) => m.id === msg.id) ? prev : [...prev, msg]));
      }
      setText("");
    } finally {
      setSending(false);
    }
  };

  const handleSendSampleKitchenPhoto = async () => {
    if (!currentBooking) return;
    const senderId = userProfile?.id || currentBooking.customer_id;
    const { data: inserted } = await supabase
      .from("messages")
      .insert({
        booking_id: currentBooking.id,
        sender_id: senderId,
        sender_role: userProfile?.role === "chef" ? "chef" : "customer",
        content: "Mutfak / Tabak hazırlık fotoğrafı paylaşıldı:",
        attachment_url:
          "https://images.unsplash.com/photo-1556911220-bff31c812dba?auto=format&fit=crop&w=800&q=80",
        delivery_status: "sent",
      })
      .select("*")
      .single();

    if (inserted) {
      const msg = inserted as unknown as ChatMessageItem;
      setMessages((prev) => (prev.some((m) => m.id === msg.id) ? prev : [...prev, msg]));
    }
  };

  if (loading) {
    return (
      <div className="pt-36 flex justify-center">
        <Loader2 className="w-8 h-8 animate-spin text-secondary" />
      </div>
    );
  }

  return (
    <main className="pt-24 md:pt-28 px-6 max-w-4xl mx-auto w-full space-y-4">
      {/* Top Bar */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 border-b border-border pb-4">
        <Link
          href={currentBooking ? `/tracker?bookingId=${currentBooking.id}` : "/tracker"}
          className="flex items-center gap-2 text-sm font-semibold text-foreground hover:opacity-80"
        >
          <ArrowLeft className="w-4 h-4" /> Canlı Takip Ekranına Dön
        </Link>

        <div className="flex items-center gap-3">
          <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
          <select
            value={activeBookingId}
            onChange={(e) => setActiveBookingId(e.target.value)}
            className="bg-card border border-border rounded-xl px-3 py-1.5 text-xs font-bold"
          >
            {bookings.map((b) => (
              <option key={b.id} value={b.id}>
                {b.booking_code} — {b.provider?.user?.full_name}
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* Chat Container */}
      <div className="bg-card border border-border rounded-3xl shadow-sm overflow-hidden flex flex-col h-[560px]">
        {/* Chat Header */}
        <div className="p-4 border-b border-border flex items-center justify-between bg-muted/30">
          <div className="flex items-center gap-3">
            <img
              src={
                currentBooking?.provider?.user?.avatar_url ||
                "https://images.unsplash.com/photo-1577219491135-ce391730fb2c?auto=format&fit=crop&w=300&q=80"
              }
              alt="Şef"
              className="w-10 h-10 rounded-full object-cover"
            />
            <div>
              <div className="font-bold text-sm">
                {currentBooking?.provider?.user?.full_name || "Özel Şef"}
              </div>
              <div className="text-xs text-muted-foreground">
                {currentBooking?.provider?.title || "Canlı Sohbet"}
              </div>
            </div>
          </div>

          <Button
            variant="outline"
            size="sm"
            onClick={handleSendSampleKitchenPhoto}
            className="rounded-full text-xs gap-1.5"
          >
            <ImageIcon className="w-3.5 h-3.5 text-secondary" /> Mutfak Fotoğrafı Gönder
          </Button>
        </div>

        {/* Messages Feed */}
        <div className="flex-1 p-6 overflow-y-auto space-y-4">
          {messages.length === 0 ? (
            <div className="text-center py-16 text-xs text-muted-foreground">
              Bu rezervasyon için henüz mesaj yok. İlk mesajı aşağıdan gönderebilirsiniz.
            </div>
          ) : (
            messages.map((m) => {
              const isCustomerMsg = m.sender_role === "customer";
              return (
                <div
                  key={m.id}
                  className={`flex ${isCustomerMsg ? "justify-end" : "justify-start"}`}
                >
                  <div
                    className={`p-4 rounded-2xl max-w-md text-xs md:text-sm space-y-2 ${
                      isCustomerMsg
                        ? "bg-primary text-primary-foreground"
                        : "bg-muted text-foreground"
                    }`}
                  >
                    <div className="text-[10px] font-bold uppercase opacity-75">
                      {isCustomerMsg
                        ? currentBooking?.customer?.full_name || "Müşteri"
                        : currentBooking?.provider?.user?.full_name || "Şef"}
                    </div>
                    <div>{m.content}</div>
                    {m.attachment_url && (
                      <img
                        src={m.attachment_url}
                        alt="Ek Görsel"
                        className="rounded-xl max-h-44 object-cover mt-2"
                      />
                    )}
                    <div className="text-[10px] opacity-65 text-right">
                      {new Date(m.created_at).toLocaleTimeString("tr-TR", {
                        hour: "2-digit",
                        minute: "2-digit",
                      })}
                    </div>
                  </div>
                </div>
              );
            })
          )}
        </div>

        {/* Input Footer */}
        <form
          onSubmit={handleSendMessage}
          className="p-4 border-t border-border flex items-center gap-3 bg-card"
        >
          <Input
            value={text}
            onChange={(e) => setText(e.target.value)}
            placeholder="Şefe veya müşteriye mesajınızı yazın..."
            className="flex-1"
          />
          <Button
            type="submit"
            disabled={sending}
            size="icon"
            className="rounded-full shrink-0 cursor-pointer"
          >
            {sending ? <Loader2 className="w-4 h-4 animate-spin" /> : <Send className="w-4 h-4" />}
          </Button>
        </form>
      </div>
    </main>
  );
}

export default function ChatPage() {
  return (
    <div className="min-h-screen bg-background text-foreground antialiased pb-24 md:pb-16">
      <Header />
      <React.Suspense
        fallback={
          <div className="pt-36 flex justify-center">
            <Loader2 className="w-8 h-8 animate-spin text-secondary" />
          </div>
        }
      >
        <ChatContent />
      </React.Suspense>
      <MobileBottomNav />
    </div>
  );
}
