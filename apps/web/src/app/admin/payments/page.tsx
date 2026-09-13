'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import { supabase } from '@/lib/supabase';
import { 
  CreditCard, 
  DollarSign, 
  Lock, 
  CheckCircle, 
  RotateCcw, 
  ShieldCheck, 
  RefreshCw, 
  ArrowUpRight, 
  Calendar, 
  User, 
  Percent, 
  FileText,
  AlertCircle
} from 'lucide-react';

interface PaymentItem {
  id: string;
  booking_id: string;
  amount: number;
  platform_fee: number;
  provider_earnings: number;
  escrow_status: 'held' | 'released' | 'refunded';
  payment_gateway: string;
  transaction_ref?: string;
  created_at: string;
  booking?: {
    event_date: string;
    event_time: string;
    guest_count: number;
    customer?: { full_name: string; email: string };
    provider?: { 
      id: string;
      provider_type: string;
      user?: { full_name: string; email: string };
    };
    menu?: { title: string };
  };
}

const MOCK_PAYMENTS: PaymentItem[] = [
  {
    id: 'pay-001',
    booking_id: 'book-101',
    amount: 4500.00,
    platform_fee: 450.00, // 10%
    provider_earnings: 4050.00, // 90%
    escrow_status: 'held',
    payment_gateway: 'iyzico',
    transaction_ref: 'TX-ESCROW-8F92A1',
    created_at: new Date(Date.now() - 3600000 * 2).toISOString(),
    booking: {
      event_date: '2026-08-25',
      event_time: '19:30',
      guest_count: 6,
      customer: { full_name: 'Ahmet Yılmaz', email: 'ahmet@example.com' },
      provider: {
        id: 'prov-001',
        provider_type: 'chef',
        user: { full_name: 'Şef Mehmet Yılmaz', email: 'mehmet.chef@gastrohost.com' }
      },
      menu: { title: 'Ege Otları ve Deniz Ürünleri Menüsü' }
    }
  },
  {
    id: 'pay-002',
    booking_id: 'book-102',
    amount: 3200.00,
    platform_fee: 320.00, // 10%
    provider_earnings: 2880.00, // 90%
    escrow_status: 'released',
    payment_gateway: 'iyzico',
    transaction_ref: 'TX-ESCROW-3B71C9',
    created_at: new Date(Date.now() - 3600000 * 24).toISOString(),
    booking: {
      event_date: '2026-08-22',
      event_time: '20:00',
      guest_count: 4,
      customer: { full_name: 'Zeynep Kaya', email: 'zeynep@example.com' },
      provider: {
        id: 'prov-002',
        provider_type: 'chef',
        user: { full_name: 'Şef Ayşe Kaya', email: 'ayse.kaya@gastrohost.com' }
      },
      menu: { title: 'İtalyan Fine-Dining Gecesi' }
    }
  },
  {
    id: 'pay-003',
    booking_id: 'book-103',
    amount: 2800.00,
    platform_fee: 280.00, // 10%
    provider_earnings: 2520.00, // 90%
    escrow_status: 'refunded',
    payment_gateway: 'stripe',
    transaction_ref: 'TX-ESCROW-7D12E4',
    created_at: new Date(Date.now() - 3600000 * 48).toISOString(),
    booking: {
      event_date: '2026-08-20',
      event_time: '18:00',
      guest_count: 8,
      customer: { full_name: 'Burak Demir', email: 'burak@example.com' },
      provider: {
        id: 'prov-003',
        provider_type: 'bartender',
        user: { full_name: 'Barmen Can Demir', email: 'can.mixology@gastrohost.com' }
      },
      menu: { title: 'İmza Kokteyl Atölyesi ve Bar Servisi' }
    }
  }
];

export default function AdminPaymentsPage() {
  const [payments, setPayments] = useState<PaymentItem[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [filterStatus, setFilterStatus] = useState<'all' | 'held' | 'released' | 'refunded'>('all');

  const fetchPayments = async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('payments')
        .select(`
          *,
          booking:bookings (
            event_date,
            event_time,
            guest_count,
            customer:profiles (full_name, email),
            provider:provider_profiles (
              id,
              provider_type,
              user:profiles (full_name, email)
            ),
            menu:menus (title)
          )
        `)
        .order('created_at', { ascending: false });

      if (error || !data || data.length === 0) {
        console.log('Using fallback demo payment data');
        setPayments(MOCK_PAYMENTS);
      } else {
        setPayments(data as unknown as PaymentItem[]);
      }
    } catch (e) {
      console.error('Fetch payments error:', e);
      setPayments(MOCK_PAYMENTS);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchPayments();
  }, []);

  // Action: Manual Release Payout
  const handleReleasePayout = async (bookingId: string) => {
    try {
      const { error } = await supabase.rpc('release_escrow_payout', {
        p_booking_id: bookingId
      });

      if (error) {
        await supabase
          .from('payments')
          .update({ escrow_status: 'released', released_at: new Date().toISOString() })
          .eq('booking_id', bookingId);
      }

      setPayments(prev => prev.map(p => {
        if (p.booking_id === bookingId) {
          return { ...p, escrow_status: 'released' };
        }
        return p;
      }));
    } catch (e) {
      console.error('Release error:', e);
    }
  };

  // Action: Manual Refund
  const handleRefundPayment = async (bookingId: string) => {
    try {
      const { error } = await supabase.rpc('refund_escrow_payment', {
        p_booking_id: bookingId,
        p_reason: 'Admin panelinden manuel iade yapıldı'
      });

      if (error) {
        await supabase
          .from('payments')
          .update({ escrow_status: 'refunded', refunded_at: new Date().toISOString() })
          .eq('booking_id', bookingId);
      }

      setPayments(prev => prev.map(p => {
        if (p.booking_id === bookingId) {
          return { ...p, escrow_status: 'refunded' };
        }
        return p;
      }));
    } catch (e) {
      console.error('Refund error:', e);
    }
  };

  // Financial Metrics Calculation
  const totalHeld = payments.filter(p => p.escrow_status === 'held').reduce((acc, p) => acc + (p.amount || 0), 0);
  const totalCommissionRevenue = payments.filter(p => p.escrow_status !== 'refunded').reduce((acc, p) => acc + (p.platform_fee || (p.amount * 0.10)), 0);
  const totalReleasedProviderEarnings = payments.filter(p => p.escrow_status === 'released').reduce((acc, p) => acc + (p.provider_earnings || (p.amount * 0.90)), 0);
  const totalRefunded = payments.filter(p => p.escrow_status === 'refunded').reduce((acc, p) => acc + (p.amount || 0), 0);

  const filteredPayments = payments.filter(p => filterStatus === 'all' || p.escrow_status === filterStatus);

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 font-sans p-6 md:p-10">
      <div className="max-w-7xl mx-auto space-y-8">
        
        {/* Navigation & Header */}
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 border-b border-slate-800 pb-6">
          <div>
            <div className="flex items-center gap-3">
              <CreditCard className="w-9 h-9 text-emerald-400" />
              <h1 className="text-3xl font-bold tracking-tight bg-gradient-to-r from-emerald-300 via-teal-400 to-amber-400 bg-clip-text text-transparent">
                Escrow & Finans Merkezi
              </h1>
            </div>
            <p className="text-slate-400 text-sm mt-1">
              GastroHost Pazar Yeri Ödeme Bloke, %10 Komisyon & Şef Hakediş Yönetimi
            </p>
          </div>

          {/* Admin Navigation Tabs */}
          <div className="flex items-center gap-2 bg-slate-900 p-1 border border-slate-800 rounded-xl">
            <Link 
              href="/admin/documents"
              className="px-4 py-2 text-xs font-semibold text-slate-400 hover:text-slate-200 hover:bg-slate-800/60 rounded-lg transition"
            >
              Belge İnceleme
            </Link>
            <Link
              href="/admin/payments"
              className="px-4 py-2 text-xs font-bold bg-amber-500 text-slate-950 rounded-lg shadow-sm"
            >
              Escrow & Ödemeler
            </Link>
          </div>
        </div>

        {/* Financial Metrics Overview Cards */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          
          {/* Escrow Held */}
          <div className="bg-slate-900/90 border border-slate-800 rounded-2xl p-5 backdrop-blur relative overflow-hidden">
            <div className="flex items-center justify-between text-amber-400 text-xs font-bold uppercase tracking-wider">
              <span>Havuzda Bloke (Held)</span>
              <Lock className="w-5 h-5 text-amber-400" />
            </div>
            <div className="text-3xl font-extrabold mt-3 text-amber-400">
              ₺{totalHeld.toLocaleString('tr-TR', { minimumFractionDigits: 2 })}
            </div>
            <p className="text-xs text-slate-400 mt-2">Etkinlik günü sonunu bekleyen güvenli bakiye</p>
          </div>

          {/* Platform 10% Revenue */}
          <div className="bg-slate-900/90 border border-slate-800 rounded-2xl p-5 backdrop-blur relative overflow-hidden">
            <div className="flex items-center justify-between text-emerald-400 text-xs font-bold uppercase tracking-wider">
              <span>Platform Komisyonu (%10)</span>
              <Percent className="w-5 h-5 text-emerald-400" />
            </div>
            <div className="text-3xl font-extrabold mt-3 text-emerald-400">
              ₺{totalCommissionRevenue.toLocaleString('tr-TR', { minimumFractionDigits: 2 })}
            </div>
            <p className="text-xs text-slate-400 mt-2">Pazar yeri net komisyon geliri</p>
          </div>

          {/* Provider Earnings Released */}
          <div className="bg-slate-900/90 border border-slate-800 rounded-2xl p-5 backdrop-blur relative overflow-hidden">
            <div className="flex items-center justify-between text-teal-400 text-xs font-bold uppercase tracking-wider">
              <span>Ödenen Şef Hakedişleri (%90)</span>
              <CheckCircle className="w-5 h-5 text-teal-400" />
            </div>
            <div className="text-3xl font-extrabold mt-3 text-slate-100">
              ₺{totalReleasedProviderEarnings.toLocaleString('tr-TR', { minimumFractionDigits: 2 })}
            </div>
            <p className="text-xs text-slate-400 mt-2">Şeflerin cüzdanına aktarılan net tutar</p>
          </div>

          {/* Total Refunded */}
          <div className="bg-slate-900/90 border border-slate-800 rounded-2xl p-5 backdrop-blur relative overflow-hidden">
            <div className="flex items-center justify-between text-rose-400 text-xs font-bold uppercase tracking-wider">
              <span>Toplam İadeler</span>
              <RotateCcw className="w-5 h-5 text-rose-400" />
            </div>
            <div className="text-3xl font-extrabold mt-3 text-rose-400">
              ₺{totalRefunded.toLocaleString('tr-TR', { minimumFractionDigits: 2 })}
            </div>
            <p className="text-xs text-slate-400 mt-2">Müşterilere iade edilen tutar</p>
          </div>

        </div>

        {/* Filter Controls Bar */}
        <div className="flex items-center justify-between bg-slate-900/60 p-4 border border-slate-800 rounded-xl">
          <div className="flex items-center gap-2">
            <span className="text-xs font-semibold text-slate-400 mr-2">Escrow Durum Filtresi:</span>
            {(['all', 'held', 'released', 'refunded'] as const).map(status => (
              <button
                key={status}
                onClick={() => setFilterStatus(status)}
                className={`px-3 py-1.5 rounded-lg text-xs font-bold transition capitalize ${
                  filterStatus === status
                    ? 'bg-emerald-500 text-slate-950 font-bold'
                    : 'bg-slate-800/80 hover:bg-slate-800 text-slate-400'
                }`}
              >
                {status === 'all' && 'Tüm İşlemler'}
                {status === 'held' && 'Havuzda Bloke (Held)'}
                {status === 'released' && 'Şefe Aktarıldı (Released)'}
                {status === 'refunded' && 'İade Edildi (Refunded)'}
              </button>
            ))}
          </div>

          <button
            onClick={fetchPayments}
            className="flex items-center gap-1.5 text-xs text-slate-400 hover:text-slate-200 transition"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`} />
            Yenile
          </button>
        </div>

        {/* Payment Transactions Table */}
        <div className="bg-slate-900/90 border border-slate-800 rounded-2xl overflow-hidden shadow-xl">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-slate-950/80 text-slate-400 border-b border-slate-800 uppercase font-semibold">
                <tr>
                  <th className="p-4">Referans / Gateway</th>
                  <th className="p-4">Müşteri</th>
                  <th className="p-4">Hizmet Sağlayıcı</th>
                  <th className="p-4 text-right">Toplam Tutar</th>
                  <th className="p-4 text-right">Komisyon (%10)</th>
                  <th className="p-4 text-right">Şef Hakediş (%90)</th>
                  <th className="p-4 text-center">Escrow Durumu</th>
                  <th className="p-4 text-center">Admin İşlemi</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800/60 text-slate-300">
                {loading ? (
                  <tr>
                    <td colSpan={8} className="text-center py-12">
                      <RefreshCw className="w-6 h-6 text-emerald-500 animate-spin mx-auto" />
                    </td>
                  </tr>
                ) : filteredPayments.length === 0 ? (
                  <tr>
                    <td colSpan={8} className="text-center py-12 text-slate-500">
                      Ödeme kaydı bulunamadı.
                    </td>
                  </tr>
                ) : (
                  filteredPayments.map(p => (
                    <tr key={p.id} className="hover:bg-slate-800/40 transition">
                      
                      {/* Ref & Gateway */}
                      <td className="p-4">
                        <div className="font-bold text-slate-100">{p.transaction_ref || p.id}</div>
                        <div className="text-[11px] text-amber-400 capitalize mt-0.5">
                          {p.payment_gateway || 'iyzico Pazaryeri'}
                        </div>
                      </td>

                      {/* Customer */}
                      <td className="p-4">
                        <div className="font-medium text-slate-200">
                          {p.booking?.customer?.full_name || 'Müşteri'}
                        </div>
                        <div className="text-[11px] text-slate-500">
                          {p.booking?.customer?.email}
                        </div>
                      </td>

                      {/* Provider */}
                      <td className="p-4">
                        <div className="font-medium text-slate-200">
                          {p.booking?.provider?.user?.full_name || 'Şef / Barmen'}
                        </div>
                        <div className="text-[11px] text-slate-500 capitalize">
                          {p.booking?.menu?.title || 'Menü Servisi'}
                        </div>
                      </td>

                      {/* Amounts */}
                      <td className="p-4 text-right font-bold text-slate-100">
                        ₺{p.amount?.toLocaleString('tr-TR', { minimumFractionDigits: 2 })}
                      </td>

                      <td className="p-4 text-right font-semibold text-emerald-400">
                        ₺{(p.platform_fee || p.amount * 0.10).toLocaleString('tr-TR', { minimumFractionDigits: 2 })}
                      </td>

                      <td className="p-4 text-right font-semibold text-amber-300">
                        ₺{(p.provider_earnings || p.amount * 0.90).toLocaleString('tr-TR', { minimumFractionDigits: 2 })}
                      </td>

                      {/* Escrow Status Badge */}
                      <td className="p-4 text-center">
                        {p.escrow_status === 'held' && (
                          <span className="inline-flex items-center gap-1 px-2.5 py-1 bg-amber-500/10 border border-amber-500/30 text-amber-400 rounded-full font-bold">
                            <Lock className="w-3 h-3" /> Bloke (Held)
                          </span>
                        )}
                        {p.escrow_status === 'released' && (
                          <span className="inline-flex items-center gap-1 px-2.5 py-1 bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 rounded-full font-bold">
                            <CheckCircle className="w-3 h-3" /> Şefe Aktarıldı
                          </span>
                        )}
                        {p.escrow_status === 'refunded' && (
                          <span className="inline-flex items-center gap-1 px-2.5 py-1 bg-rose-500/10 border border-rose-500/30 text-rose-400 rounded-full font-bold">
                            <RotateCcw className="w-3 h-3" /> İade Edildi
                          </span>
                        )}
                      </td>

                      {/* Actions */}
                      <td className="p-4 text-center">
                        <div className="flex items-center justify-center gap-2">
                          {p.escrow_status === 'held' && (
                            <>
                              <button
                                onClick={() => handleReleasePayout(p.booking_id)}
                                className="px-2.5 py-1 bg-emerald-500 hover:bg-emerald-600 text-slate-950 font-bold rounded-lg transition"
                                title="Blokeyi kaldır ve şefin cüzdanına aktar"
                              >
                                Aktar
                              </button>
                              <button
                                onClick={() => handleRefundPayment(p.booking_id)}
                                className="px-2.5 py-1 bg-rose-500/20 hover:bg-rose-500/30 text-rose-300 border border-rose-500/30 font-semibold rounded-lg transition"
                                title="Müşteriye iade et"
                              >
                                İade
                              </button>
                            </>
                          )}
                          {p.escrow_status !== 'held' && (
                            <span className="text-[11px] text-slate-500 italic">İşlem Tamamlandı</span>
                          )}
                        </div>
                      </td>

                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>

      </div>
    </div>
  );
}
