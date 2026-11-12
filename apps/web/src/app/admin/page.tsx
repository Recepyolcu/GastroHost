'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import { supabase } from '@/lib/supabase';
import {
  ShieldCheck,
  Users,
  CheckCircle,
  XCircle,
  Clock,
  FileText,
  CreditCard,
  RefreshCw,
  Search,
  Award,
  MapPin,
  AlertTriangle,
  ArrowLeft,
  ChefHat,
  Wine,
  Ban,
} from 'lucide-react';

interface ProviderApplicationItem {
  id: string;
  user_id: string;
  provider_type: 'chef' | 'bartender' | 'both';
  title?: string | null;
  bio?: string | null;
  education?: string | null;
  experience_years: number;
  experience_label?: string | null;
  city_region?: string | null;
  service_radius_km: number;
  hourly_rate: number;
  onboarding_status: 'draft' | 'pending_approval' | 'approved' | 'rejected' | 'suspended';
  rejection_reason?: string | null;
  is_verified: boolean;
  verification_badges?: {
    identity?: boolean;
    criminal_record?: boolean;
    hygiene_cert?: boolean;
    diploma?: boolean;
  };
  iban?: string | null;
  wallet_balance: number;
  pending_escrow: number;
  rating_avg: number;
  total_reviews: number;
  created_at: string;
  user?: {
    full_name: string;
    email: string;
    phone?: string | null;
    avatar_url?: string | null;
  };
  documents?: {
    id: string;
    document_type: string;
    status: string;
  }[];
}

export default function AdminApplicationsPage() {
  const [providers, setProviders] = useState<ProviderApplicationItem[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [filterStatus, setFilterStatus] = useState<
    'all' | 'pending_approval' | 'approved' | 'rejected' | 'draft' | 'suspended'
  >('all');
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [selectedForReject, setSelectedForReject] = useState<ProviderApplicationItem | null>(null);
  const [rejectReason, setRejectReason] = useState<string>('');
  const [actionBusyId, setActionBusyId] = useState<string | null>(null);

  const fetchProviders = async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('provider_profiles')
        .select(
          `
          *,
          user:profiles (
            full_name,
            email,
            phone,
            avatar_url
          ),
          documents:provider_documents (
            id,
            document_type,
            status
          )
        `
        )
        .order('created_at', { ascending: false });

      if (!error && data) {
        setProviders(data as unknown as ProviderApplicationItem[]);
      }
    } catch (e) {
      console.error('Error fetching provider applications:', e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchProviders();
  }, []);

  const handleUpdateApplicationStatus = async (
    provider: ProviderApplicationItem,
    newStatus: 'approved' | 'rejected' | 'suspended',
    reason: string | null = null
  ) => {
    setActionBusyId(provider.id);
    try {
      const { error } = await supabase.rpc('admin_review_provider_application', {
        p_provider_id: provider.id,
        p_new_status: newStatus,
        p_reason: reason,
      });

      if (error) {
        await supabase
          .from('provider_profiles')
          .update({
            onboarding_status: newStatus,
            is_verified: newStatus === 'approved',
            rejection_reason: newStatus === 'rejected' ? reason : null,
          })
          .eq('id', provider.id);
      }

      await fetchProviders();
      setSelectedForReject(null);
      setRejectReason('');
    } catch (e) {
      console.error('Application status update error:', e);
    } finally {
      setActionBusyId(null);
    }
  };

  const filteredProviders = providers.filter((p) => {
    const matchesStatus = filterStatus === 'all' || p.onboarding_status === filterStatus;
    const name = p.user?.full_name?.toLowerCase() || '';
    const title = p.title?.toLowerCase() || '';
    const city = p.city_region?.toLowerCase() || '';
    const q = searchTerm.toLowerCase();
    const matchesSearch = name.includes(q) || title.includes(q) || city.includes(q);
    return matchesStatus && matchesSearch;
  });

  const pendingCount = providers.filter(
    (p) => p.onboarding_status === 'pending_approval' || p.onboarding_status === 'draft'
  ).length;
  const approvedCount = providers.filter((p) => p.onboarding_status === 'approved').length;
  const rejectedCount = providers.filter(
    (p) => p.onboarding_status === 'rejected' || p.onboarding_status === 'suspended'
  ).length;

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 font-sans p-6 md:p-10">
      <div className="max-w-7xl mx-auto space-y-8">
        {/* Top Admin Header & Navigation */}
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4 border-b border-slate-800 pb-6">
          <div>
            <div className="flex items-center gap-3">
              <Link
                href="/"
                className="p-2 rounded-lg bg-slate-900 border border-slate-800 text-slate-400 hover:text-slate-200 transition"
                title="Ana Sayfaya Dön"
              >
                <ArrowLeft className="w-4 h-4" />
              </Link>
              <ShieldCheck className="w-9 h-9 text-amber-400" />
              <div>
                <h1 className="text-2xl md:text-3xl font-bold tracking-tight bg-gradient-to-r from-amber-200 via-orange-400 to-amber-500 bg-clip-text text-transparent">
                  GastroHost Yönetim Merkezi
                </h1>
                <p className="text-slate-400 text-xs md:text-sm mt-0.5">
                  Şef & Barmen Başvuru Onayları, Hibrit Güven Modeli ve %10 Komisyonlu Escrow Yönetimi
                </p>
              </div>
            </div>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            <div className="flex items-center gap-1.5 bg-slate-900 p-1.5 border border-slate-800 rounded-xl">
              <Link
                href="/admin"
                className="px-3.5 py-2 text-xs font-bold bg-amber-500 text-slate-950 rounded-lg shadow-sm flex items-center gap-1.5"
              >
                <Users className="w-3.5 h-3.5" />
                Başvurular ({providers.length})
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
                className="px-3.5 py-2 text-xs font-semibold text-slate-400 hover:text-slate-200 hover:bg-slate-800/60 rounded-lg transition flex items-center gap-1.5"
              >
                <CreditCard className="w-3.5 h-3.5" />
                Escrow & %10 Komisyon
              </Link>
            </div>

            <button
              onClick={fetchProviders}
              className="flex items-center gap-2 px-4 py-2 bg-slate-900 hover:bg-slate-800 border border-slate-700 rounded-xl text-slate-300 text-xs font-semibold transition cursor-pointer"
            >
              <RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`} />
              Yenile
            </button>
          </div>
        </div>

        {/* Summary KPI Cards */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <div
            onClick={() => setFilterStatus('all')}
            className={`cursor-pointer bg-slate-900/80 border rounded-xl p-5 transition ${
              filterStatus === 'all' ? 'ring-2 ring-indigo-500 border-indigo-500/50' : 'border-slate-800'
            }`}
          >
            <div className="flex items-center justify-between text-slate-400 text-xs font-semibold uppercase">
              <span>Toplam Sağlayıcı</span>
              <Users className="w-5 h-5 text-indigo-400" />
            </div>
            <div className="text-3xl font-bold mt-2 text-slate-100">{providers.length}</div>
            <p className="text-[11px] text-slate-500 mt-1">Sistemdeki tüm şef ve barmen profilleri</p>
          </div>

          <div
            onClick={() => setFilterStatus('pending_approval')}
            className={`cursor-pointer bg-slate-900/80 border rounded-xl p-5 transition ${
              filterStatus === 'pending_approval'
                ? 'ring-2 ring-amber-500 border-amber-500/50'
                : 'border-slate-800'
            }`}
          >
            <div className="flex items-center justify-between text-amber-400 text-xs font-semibold uppercase">
              <span>Onay / İnceleme Bekleyen</span>
              <Clock className="w-5 h-5" />
            </div>
            <div className="text-3xl font-bold mt-2 text-amber-400">{pendingCount}</div>
            <p className="text-[11px] text-slate-500 mt-1">Kimlik & Adli Sicil kontrolü bekleyenler</p>
          </div>

          <div
            onClick={() => setFilterStatus('approved')}
            className={`cursor-pointer bg-slate-900/80 border rounded-xl p-5 transition ${
              filterStatus === 'approved'
                ? 'ring-2 ring-emerald-500 border-emerald-500/50'
                : 'border-slate-800'
            }`}
          >
            <div className="flex items-center justify-between text-emerald-400 text-xs font-semibold uppercase">
              <span>Aktif & Onaylı Profiller</span>
              <CheckCircle className="w-5 h-5" />
            </div>
            <div className="text-3xl font-bold mt-2 text-emerald-400">{approvedCount}</div>
            <p className="text-[11px] text-slate-500 mt-1">Keşif ekranında rezervasyona açık olanlar</p>
          </div>

          <div
            onClick={() => setFilterStatus('rejected')}
            className={`cursor-pointer bg-slate-900/80 border rounded-xl p-5 transition ${
              filterStatus === 'rejected'
                ? 'ring-2 ring-rose-500 border-rose-500/50'
                : 'border-slate-800'
            }`}
          >
            <div className="flex items-center justify-between text-rose-400 text-xs font-semibold uppercase">
              <span>Reddedilen / Askıda</span>
              <XCircle className="w-5 h-5" />
            </div>
            <div className="text-3xl font-bold mt-2 text-rose-400">{rejectedCount}</div>
            <p className="text-[11px] text-slate-500 mt-1">Eksik belge veya kural ihlali olanlar</p>
          </div>
        </div>

        {/* Filter & Search Bar */}
        <div className="flex flex-col sm:flex-row items-center justify-between gap-4 bg-slate-900/60 p-4 border border-slate-800 rounded-xl">
          <div className="flex items-center gap-2 overflow-x-auto w-full sm:w-auto">
            {(
              [
                { id: 'all', label: 'Tümü' },
                { id: 'pending_approval', label: 'Onay Bekleyenler' },
                { id: 'approved', label: 'Onaylılar' },
                { id: 'draft', label: 'Taslak (Onboarding)' },
                { id: 'rejected', label: 'Reddedilenler' },
              ] as const
            ).map((st) => (
              <button
                key={st.id}
                onClick={() => setFilterStatus(st.id)}
                className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition whitespace-nowrap ${
                  filterStatus === st.id
                    ? 'bg-amber-500 text-slate-950 font-bold'
                    : 'bg-slate-800/80 hover:bg-slate-800 text-slate-400'
                }`}
              >
                {st.label}
              </button>
            ))}
          </div>

          <div className="relative w-full sm:w-72">
            <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" />
            <input
              type="text"
              placeholder="Şef/Barmen adı, unvan veya şehir ara..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full bg-slate-950 border border-slate-800 focus:border-amber-500 rounded-lg pl-9 pr-4 py-1.5 text-xs text-slate-200 focus:outline-none transition"
            />
          </div>
        </div>

        {/* Provider Applications List */}
        {loading ? (
          <div className="flex items-center justify-center py-20">
            <RefreshCw className="w-8 h-8 text-amber-500 animate-spin" />
          </div>
        ) : filteredProviders.length === 0 ? (
          <div className="text-center py-16 bg-slate-900/40 border border-slate-800 rounded-2xl">
            <Users className="w-12 h-12 text-slate-600 mx-auto mb-3" />
            <h3 className="text-base font-bold text-slate-300">Sağlayıcı Başvurusu Bulunamadı</h3>
            <p className="text-xs text-slate-500 mt-1">Seçili filtreye uygun şef veya barmen kaydı yok.</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {filteredProviders.map((prov) => {
              const isBusy = actionBusyId === prov.id;
              const approvedDocs = (prov.documents || []).filter((d) => d.status === 'approved').length;
              const pendingDocs = (prov.documents || []).filter((d) => d.status === 'pending').length;

              return (
                <div
                  key={prov.id}
                  className="bg-slate-900/90 border border-slate-800 rounded-2xl p-6 flex flex-col justify-between hover:border-slate-700 transition shadow-lg space-y-5"
                >
                  <div className="space-y-4">
                    {/* Top Row */}
                    <div className="flex items-start justify-between gap-4 border-b border-slate-800/80 pb-4">
                      <div className="flex items-center gap-3.5">
                        <div className="w-12 h-12 rounded-full bg-amber-500/10 border border-amber-500/30 flex items-center justify-center overflow-hidden shrink-0">
                          {prov.user?.avatar_url ? (
                            <img
                              src={prov.user.avatar_url}
                              alt={prov.user.full_name}
                              className="w-full h-full object-cover"
                            />
                          ) : prov.provider_type === 'bartender' ? (
                            <Wine className="w-6 h-6 text-amber-400" />
                          ) : (
                            <ChefHat className="w-6 h-6 text-amber-400" />
                          )}
                        </div>
                        <div>
                          <div className="flex items-center gap-2">
                            <h2 className="text-base font-bold text-slate-100">
                              {prov.user?.full_name || 'İsimsiz Sağlayıcı'}
                            </h2>
                            <span className="px-2 py-0.5 rounded bg-slate-800 text-amber-300 text-[11px] font-semibold">
                              {prov.provider_type === 'chef'
                                ? 'Özel Şef'
                                : prov.provider_type === 'bartender'
                                ? 'Barmen / Miksolojist'
                                : 'Şef & Barmen'}
                            </span>
                          </div>
                          <p className="text-xs text-slate-400 mt-0.5">
                            {prov.title || 'Profesyonel Gastronomi Uzmanı'}
                          </p>
                          <div className="flex items-center gap-3 text-[11px] text-slate-500 mt-1">
                            <span>{prov.user?.email}</span>
                            {prov.city_region && (
                              <span className="flex items-center gap-1 text-slate-400">
                                <MapPin className="w-3 h-3 text-amber-400" />
                                {prov.city_region} ({prov.service_radius_km} km)
                              </span>
                            )}
                          </div>
                        </div>
                      </div>

                      {/* Onboarding Status Pill */}
                      <div>
                        {prov.onboarding_status === 'approved' && (
                          <span className="inline-flex items-center gap-1 px-3 py-1 bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 text-xs font-bold rounded-full">
                            <CheckCircle className="w-3.5 h-3.5" /> Onaylı Profil
                          </span>
                        )}
                        {(prov.onboarding_status === 'pending_approval' ||
                          prov.onboarding_status === 'draft') && (
                          <span className="inline-flex items-center gap-1 px-3 py-1 bg-amber-500/10 border border-amber-500/30 text-amber-400 text-xs font-bold rounded-full">
                            <Clock className="w-3.5 h-3.5" />{' '}
                            {prov.onboarding_status === 'pending_approval'
                              ? 'Onay Bekliyor'
                              : 'Taslak Başvuru'}
                          </span>
                        )}
                        {(prov.onboarding_status === 'rejected' ||
                          prov.onboarding_status === 'suspended') && (
                          <span className="inline-flex items-center gap-1 px-3 py-1 bg-rose-500/10 border border-rose-500/30 text-rose-400 text-xs font-bold rounded-full">
                            <XCircle className="w-3.5 h-3.5" />{' '}
                            {prov.onboarding_status === 'rejected' ? 'Reddedildi' : 'Askıya Alındı'}
                          </span>
                        )}
                      </div>
                    </div>

                    {/* Hybrid Trust Model Status Grid */}
                    <div className="grid grid-cols-2 gap-3 bg-slate-950/60 p-3.5 rounded-xl border border-slate-800/70 text-xs">
                      <div>
                        <div className="text-[10px] uppercase font-bold text-slate-500 mb-1">
                          Zorunlu Güvenlik Doğrulaması
                        </div>
                        <div className="flex flex-wrap gap-1.5">
                          <span
                            className={`px-2 py-0.5 rounded font-semibold ${
                              prov.is_verified || prov.verification_badges?.identity
                                ? 'bg-emerald-500/15 text-emerald-400'
                                : 'bg-slate-800 text-slate-400'
                            }`}
                          >
                            {prov.is_verified || prov.verification_badges?.identity ? '✓' : '○'} Kimlik & Adli Sicil
                          </span>
                        </div>
                      </div>

                      <div>
                        <div className="text-[10px] uppercase font-bold text-slate-500 mb-1">
                          Yetkinlik Rozetleri (Opsiyonel)
                        </div>
                        <div className="flex flex-wrap gap-1.5">
                          <span
                            className={`px-2 py-0.5 rounded font-semibold flex items-center gap-1 ${
                              prov.verification_badges?.hygiene_cert
                                ? 'bg-teal-500/15 text-teal-300'
                                : 'bg-slate-800 text-slate-500'
                            }`}
                          >
                            <Award className="w-3 h-3" /> Hijyen Sertifikalı
                          </span>
                          <span
                            className={`px-2 py-0.5 rounded font-semibold flex items-center gap-1 ${
                              prov.verification_badges?.diploma
                                ? 'bg-amber-500/15 text-amber-300'
                                : 'bg-slate-800 text-slate-500'
                            }`}
                          >
                            <Award className="w-3 h-3" /> Diplomalı Şef
                          </span>
                        </div>
                      </div>
                    </div>

                    {/* Details Summary */}
                    <div className="flex flex-wrap items-center justify-between gap-2 text-xs text-slate-400 px-1">
                      <span>
                        Deneyim: <strong className="text-slate-200">{prov.experience_years} Yıl</strong>
                      </span>
                      <span>
                        Saatlik Ücret:{' '}
                        <strong className="text-amber-400">
                          ₺{Number(prov.hourly_rate || 0).toLocaleString('tr-TR')}
                        </strong>
                      </span>
                      <span>
                        Belgeler:{' '}
                        <strong className="text-emerald-400">{approvedDocs} Onaylı</strong>
                        {pendingDocs > 0 && (
                          <span className="text-amber-400 ml-1">({pendingDocs} Bekleyen)</span>
                        )}
                      </span>
                    </div>

                    {prov.rejection_reason && (
                      <div className="bg-rose-950/40 border border-rose-800/60 p-3 rounded-xl text-rose-300 text-xs flex items-start gap-2">
                        <AlertTriangle className="w-4 h-4 text-rose-400 shrink-0 mt-0.5" />
                        <div>
                          <span className="font-bold">Red / Askı Gerekçesi: </span>
                          {prov.rejection_reason}
                        </div>
                      </div>
                    )}
                  </div>

                  {/* Footer Actions */}
                  <div className="pt-4 border-t border-slate-800/80 flex items-center justify-between gap-3">
                    <Link
                      href="/admin/documents"
                      className="text-xs font-semibold text-amber-400 hover:underline flex items-center gap-1"
                    >
                      <FileText className="w-3.5 h-3.5" /> Belgelerini İncele
                    </Link>

                    <div className="flex items-center gap-2">
                      {prov.onboarding_status !== 'rejected' && (
                        <button
                          disabled={isBusy}
                          onClick={() => setSelectedForReject(prov)}
                          className="px-3 py-1.5 bg-rose-500/10 hover:bg-rose-500/20 text-rose-400 border border-rose-500/30 text-xs font-semibold rounded-lg transition cursor-pointer"
                        >
                          Reddet
                        </button>
                      )}

                      {prov.onboarding_status === 'approved' && (
                        <button
                          disabled={isBusy}
                          onClick={() =>
                            handleUpdateApplicationStatus(
                              prov,
                              'suspended',
                              'Admin tarafından geçici olarak askıya alındı.'
                            )
                          }
                          className="px-3 py-1.5 bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs font-semibold rounded-lg transition flex items-center gap-1 cursor-pointer"
                        >
                          <Ban className="w-3.5 h-3.5" /> Askıya Al
                        </button>
                      )}

                      {prov.onboarding_status !== 'approved' && (
                        <button
                          disabled={isBusy}
                          onClick={() => handleUpdateApplicationStatus(prov, 'approved')}
                          className="px-4 py-1.5 bg-emerald-500 hover:bg-emerald-600 text-slate-950 text-xs font-bold rounded-lg transition shadow-md flex items-center gap-1 cursor-pointer"
                        >
                          <CheckCircle className="w-3.5 h-3.5" /> Başvuruyu Onayla
                        </button>
                      )}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Reject Reason Modal */}
      {selectedForReject && (
        <div className="fixed inset-0 bg-slate-950/80 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl max-w-md w-full p-6 shadow-2xl space-y-4">
            <div className="flex items-center gap-3 text-rose-400">
              <AlertTriangle className="w-6 h-6" />
              <h3 className="text-lg font-bold text-slate-100">Sağlayıcı Başvurusunu Reddet</h3>
            </div>
            <p className="text-xs text-slate-400">
              <strong className="text-slate-200">{selectedForReject.user?.full_name}</strong> isimli
              sağlayıcının başvurusunu reddetme gerekçesini giriniz:
            </p>
            <textarea
              rows={4}
              value={rejectReason}
              onChange={(e) => setRejectReason(e.target.value)}
              placeholder="Örn: Kimlik ve Adli Sicil Kaydı belgeleri eksik veya okunaksız."
              className="w-full bg-slate-950 border border-slate-800 focus:border-rose-500 rounded-xl p-3 text-xs text-slate-200 focus:outline-none resize-none"
            />
            <div className="flex items-center justify-end gap-3 pt-2">
              <button
                onClick={() => {
                  setSelectedForReject(null);
                  setRejectReason('');
                }}
                className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs font-medium rounded-lg"
              >
                İptal
              </button>
              <button
                onClick={() =>
                  handleUpdateApplicationStatus(
                    selectedForReject,
                    'rejected',
                    rejectReason.trim() || 'Zorunlu güvenlik belgeleri doğrulanamadı.'
                  )
                }
                className="px-4 py-2 bg-rose-500 hover:bg-rose-600 text-slate-950 text-xs font-bold rounded-lg"
              >
                Reddi Onayla
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
