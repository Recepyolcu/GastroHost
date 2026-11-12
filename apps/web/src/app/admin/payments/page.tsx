'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import { supabase, DEFAULT_COMMISSION_RATE } from '@/lib/supabase';
import {
  CreditCard,
  Lock,
  CheckCircle,
  RotateCcw,
  RefreshCw,
  Percent,
  FileText,
  Users,
  ArrowLeft,
  Wallet,
  AlertTriangle,
} from 'lucide-react';

interface PaymentItem {
  id: string;
  booking_id: string;
  amount: number;
  commission_rate: number;
  platform_fee: number;
  provider_payout: number;
  escrow_status: 'pending' | 'held' | 'released' | 'refunded' | 'failed';
  gateway: string;
  provider_transaction_id?: string | null;
  cancel_reason?: string | null;
  created_at: string;
  booking?: {
    booking_code: string;
    event_date: string;
    event_time: string;
    guest_count: number;
    status: string;
    customer?: { full_name: string; email: string };
    provider?: {
      id: string;
      provider_type: string;
      user?: { full_name: string; email: string };
    };
    menu?: { title: string };
  };
}

interface WalletTransactionItem {
  id: string;
  provider_id: string;
  booking_id?: string | null;
  transaction_type: 'escrow_hold' | 'escrow_release' | 'escrow_refund' | 'payout_withdrawal';
  amount: number;
  status: string;
  description?: string | null;
  created_at: string;
  provider?: {
    user?: { full_name: string; email: string };
  };
}

export default function AdminPaymentsPage() {
  const [payments, setPayments] = useState<PaymentItem[]>([]);
  const [walletTx, setWalletTx] = useState<WalletTransactionItem[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [activeTab, setActiveTab] = useState<'escrow' | 'wallet'>('escrow');
  const [filterStatus, setFilterStatus] = useState<'all' | 'held' | 'released' | 'refunded'>('all');

  // Commission Rate Control (%10 Default)
  const [commissionPercent, setCommissionPercent] = useState<number>(
    Math.round(DEFAULT_COMMISSION_RATE * 100)
  );
  const [savingCommission, setSavingCommission] = useState<boolean>(false);
  const [commissionNotice, setCommissionNotice] = useState<string | null>(null);

  // Refund Modal
  const [selectedPaymentForRefund, setSelectedPaymentForRefund] = useState<PaymentItem | null>(
    null
  );
  const [refundReason, setRefundReason] = useState<string>('');
  const [busyBookingId, setBusyBookingId] = useState<string | null>(null);

  const fetchPaymentsAndLedger = async () => {
    setLoading(true);
    try {
      const [{ data: payData }, { data: txData }] = await Promise.all([
        supabase
          .from('payments')
          .select(
            `
            *,
            booking:bookings (
              booking_code,
              event_date,
              event_time,
              guest_count,
              status,
              customer:profiles!bookings_customer_id_fkey (full_name, email),
              provider:provider_profiles!bookings_provider_id_fkey (
                id,
                provider_type,
                user:profiles (full_name, email)
              ),
              menu:menus!bookings_menu_id_fkey (title)
            )
          `
          )
          .order('created_at', { ascending: false }),
        supabase
          .from('wallet_transactions')
          .select(
            `
            *,
            provider:provider_profiles (
              user:profiles (full_name, email)
            )
          `
          )
          .order('created_at', { ascending: false })
          .limit(30),
      ]);

      if (payData) {
        setPayments(payData as unknown as PaymentItem[]);
        const firstRate = payData[0]?.commission_rate;
        if (firstRate) {
          setCommissionPercent(Math.round(Number(firstRate) * 100));
        }
      }
      if (txData) {
        setWalletTx(txData as unknown as WalletTransactionItem[]);
      }
    } catch (e) {
      console.error('Fetch payments error:', e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchPaymentsAndLedger();
  }, []);

  const handleUpdateCommissionRate = async (newPercent: number) => {
    setCommissionPercent(newPercent);
    setSavingCommission(true);
    setCommissionNotice(null);
    try {
      const rateDecimal = Number((newPercent / 100).toFixed(2));
      const { error } = await supabase.rpc('admin_update_commission_rate', {
        p_rate: rateDecimal,
      });
      if (!error) {
        setCommissionNotice(`Pazar yeri komisyonu %${newPercent} olarak güncellendi.`);
        await fetchPaymentsAndLedger();
      }
    } catch (e) {
      console.error('Update commission error:', e);
    } finally {
      setSavingCommission(false);
    }
  };

  const handleReleasePayout = async (bookingId: string) => {
    setBusyBookingId(bookingId);
    try {
      const { error } = await supabase.rpc('release_escrow_payout', {
        p_booking_id: bookingId,
      });

      if (error) {
        await supabase
          .from('payments')
          .update({ escrow_status: 'released', released_at: new Date().toISOString() })
          .eq('booking_id', bookingId);
      }

      await fetchPaymentsAndLedger();
    } catch (e) {
      console.error('Release error:', e);
    } finally {
      setBusyBookingId(null);
    }
  };

  const handleConfirmRefund = async () => {
    if (!selectedPaymentForRefund) return;
    const bookingId = selectedPaymentForRefund.booking_id;
    const reason =
      refundReason.trim() || 'Admin panelinden uyuşmazlık/iptal nedeniyle müşteriye iade edildi.';

    setBusyBookingId(bookingId);
    try {
      const { error } = await supabase.rpc('refund_escrow_payment', {
        p_booking_id: bookingId,
        p_reason: reason,
      });

      if (error) {
        await supabase
          .from('payments')
          .update({
            escrow_status: 'refunded',
            refunded_at: new Date().toISOString(),
            cancel_reason: reason,
          })
          .eq('booking_id', bookingId);
      }

      setSelectedPaymentForRefund(null);
      setRefundReason('');
      await fetchPaymentsAndLedger();
    } catch (e) {
      console.error('Refund error:', e);
    } finally {
      setBusyBookingId(null);
    }
  };

  const totalHeld = payments
    .filter((p) => p.escrow_status === 'held')
    .reduce((acc, p) => acc + Number(p.amount || 0), 0);

  const totalCommissionRevenue = payments
    .filter((p) => p.escrow_status !== 'refunded')
    .reduce((acc, p) => acc + Number(p.platform_fee || Number(p.amount) * 0.1), 0);

  const totalReleasedProviderEarnings = payments
    .filter((p) => p.escrow_status === 'released')
    .reduce((acc, p) => acc + Number(p.provider_payout || Number(p.amount) * 0.9), 0);

  const totalRefunded = payments
    .filter((p) => p.escrow_status === 'refunded')
    .reduce((acc, p) => acc + Number(p.amount || 0), 0);

  const filteredPayments = payments.filter(
    (p) => filterStatus === 'all' || p.escrow_status === filterStatus
  );

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 font-sans p-6 md:p-10">
      <div className="max-w-7xl mx-auto space-y-8">
        {/* Navigation & Header */}
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4 border-b border-slate-800 pb-6">
          <div className="flex items-center gap-3">
            <Link
              href="/"
              className="p-2 rounded-lg bg-slate-900 border border-slate-800 text-slate-400 hover:text-slate-200 transition"
              title="Ana Sayfaya Dön"
            >
              <ArrowLeft className="w-4 h-4" />
            </Link>
            <CreditCard className="w-9 h-9 text-emerald-400" />
            <div>
              <h1 className="text-2xl md:text-3xl font-bold tracking-tight bg-gradient-to-r from-emerald-300 via-teal-400 to-amber-400 bg-clip-text text-transparent">
                Escrow, %10 Komisyon & Uyuşmazlık Merkezi
              </h1>
              <p className="text-slate-400 text-xs md:text-sm mt-0.5">
                GastroHost Pazar Yeri Ödeme Bloke, %{commissionPercent} Komisyon ve %{100 - commissionPercent} Şef Hakediş Yönetimi
              </p>
            </div>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            <div className="flex items-center gap-1.5 bg-slate-900 p-1.5 border border-slate-800 rounded-xl">
              <Link
                href="/admin"
                className="px-3.5 py-2 text-xs font-semibold text-slate-400 hover:text-slate-200 hover:bg-slate-800/60 rounded-lg transition flex items-center gap-1.5"
              >
                <Users className="w-3.5 h-3.5" />
                Başvurular
              </Link>
              <Link
                href="/admin/documents"
                className="px-3.5 py-2 text-xs font-semibold text-slate-400 hover:text-slate-200 hover:bg-slate-800/60 rounded-lg transition flex items-center gap-1.5"
              >
                <FileText className="w-3.5 h-3.5" />
                Belge & Rozet Onayı
              </Link>
              <Link
                href="/admin/payments"
                className="px-3.5 py-2 text-xs font-bold bg-amber-500 text-slate-950 rounded-lg shadow-sm flex items-center gap-1.5"
              >
                <CreditCard className="w-3.5 h-3.5" />
                Escrow & %10 Komisyon
              </Link>
            </div>

            <button
              onClick={fetchPaymentsAndLedger}
              className="flex items-center gap-2 px-4 py-2 bg-slate-900 hover:bg-slate-800 border border-slate-700 rounded-xl text-slate-300 text-xs font-semibold transition cursor-pointer"
            >
              <RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`} />
              Yenile
            </button>
          </div>
        </div>

        {/* Financial Metrics Overview Cards */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <div className="bg-slate-900/90 border border-slate-800 rounded-2xl p-5">
            <div className="flex items-center justify-between text-amber-400 text-xs font-bold uppercase tracking-wider">
              <span>Havuzda Bloke (Held)</span>
              <Lock className="w-5 h-5 text-amber-400" />
            </div>
            <div className="text-3xl font-extrabold mt-3 text-amber-400">
              ₺{totalHeld.toLocaleString('tr-TR', { minimumFractionDigits: 2 })}
            </div>
            <p className="text-xs text-slate-400 mt-2">Etkinlik sonu onayını bekleyen güvenli bakiye</p>
          </div>

          <div className="bg-slate-900/90 border border-slate-800 rounded-2xl p-5">
            <div className="flex items-center justify-between text-emerald-400 text-xs font-bold uppercase tracking-wider">
              <span>Platform Komisyonu (%{commissionPercent})</span>
              <Percent className="w-5 h-5 text-emerald-400" />
            </div>
            <div className="text-3xl font-extrabold mt-3 text-emerald-400">
              ₺{totalCommissionRevenue.toLocaleString('tr-TR', { minimumFractionDigits: 2 })}
            </div>
            <p className="text-xs text-slate-400 mt-2">Pazar yeri net komisyon geliri</p>
          </div>

          <div className="bg-slate-900/90 border border-slate-800 rounded-2xl p-5">
            <div className="flex items-center justify-between text-teal-400 text-xs font-bold uppercase tracking-wider">
              <span>Ödenen Şef Hakedişleri (%{100 - commissionPercent})</span>
              <CheckCircle className="w-5 h-5 text-teal-400" />
            </div>
            <div className="text-3xl font-extrabold mt-3 text-slate-100">
              ₺{totalReleasedProviderEarnings.toLocaleString('tr-TR', { minimumFractionDigits: 2 })}
            </div>
            <p className="text-xs text-slate-400 mt-2">Sağlayıcı cüzdanlarına aktarılan net tutar</p>
          </div>

          <div className="bg-slate-900/90 border border-slate-800 rounded-2xl p-5">
            <div className="flex items-center justify-between text-rose-400 text-xs font-bold uppercase tracking-wider">
              <span>Toplam İadeler</span>
              <RotateCcw className="w-5 h-5 text-rose-400" />
            </div>
            <div className="text-3xl font-extrabold mt-3 text-rose-400">
              ₺{totalRefunded.toLocaleString('tr-TR', { minimumFractionDigits: 2 })}
            </div>
            <p className="text-xs text-slate-400 mt-2">Müşterilere iade edilen toplam tutar</p>
          </div>
        </div>

        {/* Marketplace Commission Rate Control Bar */}
        <div className="bg-slate-900/70 border border-slate-800 rounded-2xl p-5 flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <div className="flex items-center gap-2 text-sm font-bold text-slate-100">
              <Percent className="w-4 h-4 text-emerald-400" />
              Pazar Yeri Komisyon Oranı Yönetimi (Varsayılan: %10)
            </div>
            <p className="text-xs text-slate-400 mt-0.5">
              Aktif (bloke) rezervasyonlarda kesilecek platform komisyonu ve sağlayıcı net hakediş dağılımı.
            </p>
            {commissionNotice && (
              <p className="text-xs text-emerald-400 font-semibold mt-1">{commissionNotice}</p>
            )}
          </div>

          <div className="flex items-center gap-2">
            {[10, 12, 15, 20].map((rate) => (
              <button
                key={rate}
                disabled={savingCommission}
                onClick={() => handleUpdateCommissionRate(rate)}
                className={`px-3.5 py-2 rounded-xl text-xs font-bold transition cursor-pointer ${
                  commissionPercent === rate
                    ? 'bg-emerald-500 text-slate-950 shadow-sm'
                    : 'bg-slate-800 hover:bg-slate-700 text-slate-300'
                }`}
              >
                %{rate} {rate === 10 && '(Standart)'}
              </button>
            ))}
          </div>
        </div>

        {/* View Switcher & Status Filters */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-slate-900/60 p-4 border border-slate-800 rounded-xl">
          <div className="flex items-center gap-2">
            <button
              onClick={() => setActiveTab('escrow')}
              className={`px-3.5 py-1.5 rounded-lg text-xs font-bold flex items-center gap-1.5 transition ${
                activeTab === 'escrow'
                  ? 'bg-amber-500 text-slate-950'
                  : 'bg-slate-800 text-slate-400 hover:text-slate-200'
              }`}
            >
              <CreditCard className="w-3.5 h-3.5" /> Escrow Ödemeleri ({payments.length})
            </button>
            <button
              onClick={() => setActiveTab('wallet')}
              className={`px-3.5 py-1.5 rounded-lg text-xs font-bold flex items-center gap-1.5 transition ${
                activeTab === 'wallet'
                  ? 'bg-amber-500 text-slate-950'
                  : 'bg-slate-800 text-slate-400 hover:text-slate-200'
              }`}
            >
              <Wallet className="w-3.5 h-3.5" /> Cüzdan Hareketleri ({walletTx.length})
            </button>
          </div>

          {activeTab === 'escrow' && (
            <div className="flex items-center gap-2 overflow-x-auto">
              {(['all', 'held', 'released', 'refunded'] as const).map((status) => (
                <button
                  key={status}
                  onClick={() => setFilterStatus(status)}
                  className={`px-3 py-1.5 rounded-lg text-xs font-bold transition ${
                    filterStatus === status
                      ? 'bg-emerald-500 text-slate-950'
                      : 'bg-slate-800/80 hover:bg-slate-800 text-slate-400'
                  }`}
                >
                  {status === 'all' && 'Tümü'}
                  {status === 'held' && 'Bloke (Held)'}
                  {status === 'released' && 'Aktarıldı (Released)'}
                  {status === 'refunded' && 'İade (Refunded)'}
                </button>
              ))}
            </div>
          )}
        </div>

        {/* Tab 1: Escrow Payments Table */}
        {activeTab === 'escrow' ? (
          <div className="bg-slate-900/90 border border-slate-800 rounded-2xl overflow-hidden shadow-xl">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-slate-950/80 text-slate-400 border-b border-slate-800 uppercase font-semibold">
                  <tr>
                    <th className="p-4">Rezervasyon / Gateway</th>
                    <th className="p-4">Müşteri</th>
                    <th className="p-4">Sağlayıcı & Menü</th>
                    <th className="p-4 text-right">Toplam Tutar</th>
                    <th className="p-4 text-right">Komisyon (%{commissionPercent})</th>
                    <th className="p-4 text-right">Net Hakediş (%{100 - commissionPercent})</th>
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
                    filteredPayments.map((p) => {
                      const amount = Number(p.amount || 0);
                      const fee = Number(p.platform_fee || amount * 0.1);
                      const payout = Number(p.provider_payout || amount * 0.9);
                      const isBusy = busyBookingId === p.booking_id;

                      return (
                        <tr key={p.id} className="hover:bg-slate-800/40 transition">
                          <td className="p-4">
                            <div className="font-bold text-slate-100">
                              {p.booking?.booking_code || p.provider_transaction_id || p.id.slice(0, 8)}
                            </div>
                            <div className="text-[11px] text-amber-400 mt-0.5">
                              {p.provider_transaction_id || 'IYZ-ESCROW'} •{' '}
                              <span className="uppercase">{p.gateway || 'iyzico'}</span>
                            </div>
                          </td>

                          <td className="p-4">
                            <div className="font-medium text-slate-200">
                              {p.booking?.customer?.full_name || 'Müşteri'}
                            </div>
                            <div className="text-[11px] text-slate-500">
                              {p.booking?.customer?.email}
                            </div>
                          </td>

                          <td className="p-4">
                            <div className="font-medium text-slate-200">
                              {p.booking?.provider?.user?.full_name || 'Şef / Barmen'}
                            </div>
                            <div className="text-[11px] text-slate-500">
                              {p.booking?.menu?.title || 'Özel Gastronomi Hizmeti'} ({p.booking?.guest_count || 2} Kişi)
                            </div>
                          </td>

                          <td className="p-4 text-right font-bold text-slate-100">
                            ₺{amount.toLocaleString('tr-TR', { minimumFractionDigits: 2 })}
                          </td>

                          <td className="p-4 text-right font-semibold text-emerald-400">
                            ₺{fee.toLocaleString('tr-TR', { minimumFractionDigits: 2 })}
                          </td>

                          <td className="p-4 text-right font-semibold text-amber-300">
                            ₺{payout.toLocaleString('tr-TR', { minimumFractionDigits: 2 })}
                          </td>

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
                              <div>
                                <span className="inline-flex items-center gap-1 px-2.5 py-1 bg-rose-500/10 border border-rose-500/30 text-rose-400 rounded-full font-bold">
                                  <RotateCcw className="w-3 h-3" /> İade Edildi
                                </span>
                                {p.cancel_reason && (
                                  <div className="text-[10px] text-rose-300/80 mt-1 max-w-[160px] mx-auto truncate">
                                    {p.cancel_reason}
                                  </div>
                                )}
                              </div>
                            )}
                          </td>

                          <td className="p-4 text-center">
                            <div className="flex items-center justify-center gap-2">
                              {p.escrow_status === 'held' ? (
                                <>
                                  <button
                                    disabled={isBusy}
                                    onClick={() => handleReleasePayout(p.booking_id)}
                                    className="px-3 py-1.5 bg-emerald-500 hover:bg-emerald-600 text-slate-950 font-bold rounded-lg transition cursor-pointer"
                                    title="Blokeyi kaldır ve %90 net hakedişi şefin cüzdanına aktar"
                                  >
                                    Hakedişi Aktar
                                  </button>
                                  <button
                                    disabled={isBusy}
                                    onClick={() => setSelectedPaymentForRefund(p)}
                                    className="px-3 py-1.5 bg-rose-500/20 hover:bg-rose-500/30 text-rose-300 border border-rose-500/30 font-semibold rounded-lg transition cursor-pointer"
                                    title="Uyuşmazlık veya iptal nedeniyle müşteriye iade et"
                                  >
                                    İade Et
                                  </button>
                                </>
                              ) : (
                                <span className="text-[11px] text-slate-500 italic">
                                  İşlem Tamamlandı
                                </span>
                              )}
                            </div>
                          </td>
                        </tr>
                      );
                    })
                  )}
                </tbody>
              </table>
            </div>
          </div>
        ) : (
          /* Tab 2: Wallet Transactions Ledger */
          <div className="bg-slate-900/90 border border-slate-800 rounded-2xl overflow-hidden shadow-xl">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-slate-950/80 text-slate-400 border-b border-slate-800 uppercase font-semibold">
                  <tr>
                    <th className="p-4">Tarih</th>
                    <th className="p-4">Sağlayıcı</th>
                    <th className="p-4">İşlem Tipi</th>
                    <th className="p-4">Açıklama</th>
                    <th className="p-4 text-right">Net Tutar</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-800/60 text-slate-300">
                  {walletTx.map((tx) => (
                    <tr key={tx.id} className="hover:bg-slate-800/40 transition">
                      <td className="p-4 text-slate-400">
                        {new Date(tx.created_at).toLocaleString('tr-TR')}
                      </td>
                      <td className="p-4 font-semibold text-slate-200">
                        {tx.provider?.user?.full_name || 'Şef / Barmen'}
                      </td>
                      <td className="p-4">
                        <span
                          className={`px-2.5 py-1 rounded-full font-bold text-[11px] ${
                            tx.transaction_type === 'escrow_release'
                              ? 'bg-emerald-500/15 text-emerald-400'
                              : tx.transaction_type === 'escrow_hold'
                              ? 'bg-amber-500/15 text-amber-400'
                              : 'bg-rose-500/15 text-rose-400'
                          }`}
                        >
                          {tx.transaction_type === 'escrow_hold' && 'Escrow Blokaj'}
                          {tx.transaction_type === 'escrow_release' && 'Cüzdana Aktarım'}
                          {tx.transaction_type === 'escrow_refund' && 'İptal / İade'}
                          {tx.transaction_type === 'payout_withdrawal' && 'IBAN Çekim'}
                        </span>
                      </td>
                      <td className="p-4 text-slate-400">{tx.description}</td>
                      <td className="p-4 text-right font-bold text-slate-100">
                        ₺{Number(tx.amount || 0).toLocaleString('tr-TR', { minimumFractionDigits: 2 })}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>

      {/* Refund / Dispute Modal */}
      {selectedPaymentForRefund && (
        <div className="fixed inset-0 bg-slate-950/80 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl max-w-md w-full p-6 shadow-2xl space-y-4">
            <div className="flex items-center gap-3 text-rose-400">
              <AlertTriangle className="w-6 h-6" />
              <h3 className="text-lg font-bold text-slate-100">Escrow Ödemesini İade Et</h3>
            </div>
            <p className="text-xs text-slate-400">
              <strong className="text-slate-200">
                {selectedPaymentForRefund.booking?.customer?.full_name}
              </strong>{' '}
              müşterisine{' '}
              <strong className="text-amber-400">
                ₺{Number(selectedPaymentForRefund.amount).toLocaleString('tr-TR')}
              </strong>{' '}
              tutarı iade etmek üzeresiniz. Lütfen iptal/uyuşmazlık gerekçesini yazınız:
            </p>
            <textarea
              rows={3}
              value={refundReason}
              onChange={(e) => setRefundReason(e.target.value)}
              placeholder="Örn: Müşteri 48 saat öncesinden iptal talebinde bulundu."
              className="w-full bg-slate-950 border border-slate-800 focus:border-rose-500 rounded-xl p-3 text-xs text-slate-200 focus:outline-none resize-none"
            />
            <div className="flex items-center justify-end gap-3 pt-2">
              <button
                onClick={() => {
                  setSelectedPaymentForRefund(null);
                  setRefundReason('');
                }}
                className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs font-medium rounded-lg"
              >
                Vazgeç
              </button>
              <button
                onClick={handleConfirmRefund}
                className="px-4 py-2 bg-rose-500 hover:bg-rose-600 text-slate-950 text-xs font-bold rounded-lg"
              >
                İadeyi Onayla
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
