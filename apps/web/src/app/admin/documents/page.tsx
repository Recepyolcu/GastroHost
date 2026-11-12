'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import { supabase } from '@/lib/supabase';
import {
  FileText,
  CheckCircle,
  XCircle,
  Clock,
  ExternalLink,
  Filter,
  Search,
  ShieldCheck,
  AlertTriangle,
  User,
  Award,
  RefreshCw,
  Eye,
  Users,
  CreditCard,
  ArrowLeft,
} from 'lucide-react';

interface DocumentItem {
  id: string;
  provider_id: string;
  document_type:
    | 'identity'
    | 'criminal_record'
    | 'hygiene_cert'
    | 'diploma'
    | 'portfolio'
    | 'other';
  file_url: string;
  status: 'pending' | 'approved' | 'rejected';
  rejection_reason?: string | null;
  created_at: string;
  provider?: {
    id: string;
    provider_type: string;
    is_verified: boolean;
    verification_badges: {
      identity?: boolean;
      criminal_record?: boolean;
      hygiene_cert?: boolean;
      diploma?: boolean;
    };
    user?: {
      full_name: string;
      email: string;
      phone?: string;
    };
  };
}

export default function AdminDocumentsPage() {
  const [documents, setDocuments] = useState<DocumentItem[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [filterStatus, setFilterStatus] = useState<'all' | 'pending' | 'approved' | 'rejected'>(
    'all'
  );
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [selectedDocForReject, setSelectedDocForReject] = useState<DocumentItem | null>(null);
  const [rejectReason, setRejectReason] = useState<string>('');
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [busyDocId, setBusyDocId] = useState<string | null>(null);

  const fetchDocuments = async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('provider_documents')
        .select(
          `
          *,
          provider:provider_profiles (
            id,
            provider_type,
            is_verified,
            verification_badges,
            user:profiles (
              full_name,
              email,
              phone
            )
          )
        `
        )
        .order('created_at', { ascending: false });

      if (!error && data) {
        setDocuments(data as unknown as DocumentItem[]);
      }
    } catch (e) {
      console.error('Error fetching documents:', e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDocuments();
  }, []);

  const handleApprove = async (doc: DocumentItem) => {
    setBusyDocId(doc.id);
    try {
      const { error } = await supabase.rpc('admin_review_document', {
        doc_id: doc.id,
        new_status: 'approved',
        reason: null,
      });

      if (error) {
        await supabase
          .from('provider_documents')
          .update({ status: 'approved', rejection_reason: null })
          .eq('id', doc.id);
      }

      await fetchDocuments();
    } catch (e) {
      console.error('Approve error:', e);
    } finally {
      setBusyDocId(null);
    }
  };

  const handleConfirmReject = async () => {
    if (!selectedDocForReject) return;
    const doc = selectedDocForReject;
    const reason =
      rejectReason.trim() || 'Yüklenen belge geçerlilik standartlarını karşılamıyor.';

    setBusyDocId(doc.id);
    try {
      const { error } = await supabase.rpc('admin_review_document', {
        doc_id: doc.id,
        new_status: 'rejected',
        reason,
      });

      if (error) {
        await supabase
          .from('provider_documents')
          .update({ status: 'rejected', rejection_reason: reason })
          .eq('id', doc.id);
      }

      setSelectedDocForReject(null);
      setRejectReason('');
      await fetchDocuments();
    } catch (e) {
      console.error('Reject error:', e);
    } finally {
      setBusyDocId(null);
    }
  };

  const getDocTypeInfo = (type: string) => {
    switch (type) {
      case 'identity':
        return {
          label: 'T.C. Kimlik / Pasaport',
          tier: 'Zorunlu Güvenlik Belgesi',
          isMandatory: true,
        };
      case 'criminal_record':
        return {
          label: 'Adli Sicil Kaydı (e-Devlet)',
          tier: 'Zorunlu Güvenlik Belgesi',
          isMandatory: true,
        };
      case 'hygiene_cert':
        return {
          label: 'Hijyen Eğitimi Sertifikası',
          tier: 'Yetkinlik Rozeti (+Hijyen Rozeti)',
          isMandatory: false,
        };
      case 'diploma':
        return {
          label: 'Gastronomi / Aşçılık Diploması',
          tier: 'Yetkinlik Rozeti (+Diplomalı Şef Rozeti)',
          isMandatory: false,
        };
      case 'portfolio':
        return {
          label: 'Portfolyo & Sunum Görseli',
          tier: 'Portfolyo Medyası',
          isMandatory: false,
        };
      default:
        return {
          label: 'Diğer Belge',
          tier: 'Ek Belge',
          isMandatory: false,
        };
    }
  };

  const filteredDocs = documents.filter((doc) => {
    const matchesStatus = filterStatus === 'all' || doc.status === filterStatus;
    const providerName = doc.provider?.user?.full_name?.toLowerCase() || '';
    const docType = getDocTypeInfo(doc.document_type).label.toLowerCase();
    const matchesSearch =
      providerName.includes(searchTerm.toLowerCase()) ||
      docType.includes(searchTerm.toLowerCase());
    return matchesStatus && matchesSearch;
  });

  const pendingCount = documents.filter((d) => d.status === 'pending').length;
  const approvedCount = documents.filter((d) => d.status === 'approved').length;
  const rejectedCount = documents.filter((d) => d.status === 'rejected').length;

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 font-sans p-6 md:p-10">
      <div className="max-w-7xl mx-auto space-y-8">
        {/* Header & Admin Nav */}
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4 border-b border-slate-800 pb-6">
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
                Hibrit Güven & Rozet Doğrulama Merkezi
              </h1>
              <p className="text-slate-400 text-xs md:text-sm mt-0.5">
                Zorunlu Kimlik/Adli Sicil Doğrulaması ve Opsiyonel Hijyen/Diploma Rozeti Ataması
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
                className="px-3.5 py-2 text-xs font-bold bg-amber-500 text-slate-950 rounded-lg shadow-sm flex items-center gap-1.5"
              >
                <FileText className="w-3.5 h-3.5" />
                Belge & Rozet Onayı ({documents.length})
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
              onClick={fetchDocuments}
              className="flex items-center gap-2 px-4 py-2 bg-slate-900 hover:bg-slate-800 border border-slate-700 rounded-xl text-slate-300 text-xs font-semibold transition cursor-pointer"
            >
              <RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`} />
              Yenile
            </button>
          </div>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <div
            onClick={() => setFilterStatus('all')}
            className={`cursor-pointer bg-slate-900/80 border rounded-xl p-5 transition ${
              filterStatus === 'all' ? 'ring-2 ring-indigo-500 border-indigo-500/50' : 'border-slate-800'
            }`}
          >
            <div className="flex items-center justify-between text-slate-400 text-xs font-semibold uppercase tracking-wider">
              <span>Toplam Yüklenen</span>
              <FileText className="w-5 h-5 text-indigo-400" />
            </div>
            <div className="text-3xl font-bold mt-2 text-slate-100">{documents.length}</div>
          </div>

          <div
            onClick={() => setFilterStatus('pending')}
            className={`cursor-pointer transition bg-slate-900/80 border rounded-xl p-5 ${
              filterStatus === 'pending'
                ? 'ring-2 ring-amber-500 border-amber-500/50'
                : 'border-slate-800 hover:border-amber-500/30'
            }`}
          >
            <div className="flex items-center justify-between text-amber-400 text-xs font-semibold uppercase tracking-wider">
              <span>İnceleme Bekleyen</span>
              <Clock className="w-5 h-5" />
            </div>
            <div className="text-3xl font-bold mt-2 text-amber-400">{pendingCount}</div>
          </div>

          <div
            onClick={() => setFilterStatus('approved')}
            className={`cursor-pointer transition bg-slate-900/80 border rounded-xl p-5 ${
              filterStatus === 'approved'
                ? 'ring-2 ring-emerald-500 border-emerald-500/50'
                : 'border-slate-800 hover:border-emerald-500/30'
            }`}
          >
            <div className="flex items-center justify-between text-emerald-400 text-xs font-semibold uppercase tracking-wider">
              <span>Onaylanan Belgeler</span>
              <CheckCircle className="w-5 h-5" />
            </div>
            <div className="text-3xl font-bold mt-2 text-emerald-400">{approvedCount}</div>
          </div>

          <div
            onClick={() => setFilterStatus('rejected')}
            className={`cursor-pointer transition bg-slate-900/80 border rounded-xl p-5 ${
              filterStatus === 'rejected'
                ? 'ring-2 ring-rose-500 border-rose-500/50'
                : 'border-slate-800 hover:border-rose-500/30'
            }`}
          >
            <div className="flex items-center justify-between text-rose-400 text-xs font-semibold uppercase tracking-wider">
              <span>Reddedilenler</span>
              <XCircle className="w-5 h-5" />
            </div>
            <div className="text-3xl font-bold mt-2 text-rose-400">{rejectedCount}</div>
          </div>
        </div>

        {/* Filter Bar & Search */}
        <div className="flex flex-col sm:flex-row items-center justify-between gap-4 bg-slate-900/60 p-4 border border-slate-800 rounded-xl">
          <div className="flex items-center gap-2 overflow-x-auto w-full sm:w-auto">
            <Filter className="w-4 h-4 text-slate-500" />
            <span className="text-xs font-medium text-slate-400 mr-2">Filtre:</span>

            {(['all', 'pending', 'approved', 'rejected'] as const).map((status) => (
              <button
                key={status}
                onClick={() => setFilterStatus(status)}
                className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition ${
                  filterStatus === status
                    ? 'bg-amber-500 text-slate-950 font-bold'
                    : 'bg-slate-800/80 hover:bg-slate-800 text-slate-400'
                }`}
              >
                {status === 'all' && `Tümü (${documents.length})`}
                {status === 'pending' && `Bekleyenler (${pendingCount})`}
                {status === 'approved' && `Onaylananlar (${approvedCount})`}
                {status === 'rejected' && `Reddedilenler (${rejectedCount})`}
              </button>
            ))}
          </div>

          <div className="relative w-full sm:w-72">
            <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" />
            <input
              type="text"
              placeholder="Şef adı veya belge türü ara..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full bg-slate-950 border border-slate-800 focus:border-amber-500 rounded-lg pl-9 pr-4 py-1.5 text-xs text-slate-200 focus:outline-none transition"
            />
          </div>
        </div>

        {/* Document Cards List */}
        {loading ? (
          <div className="flex items-center justify-center py-20">
            <RefreshCw className="w-8 h-8 text-amber-500 animate-spin" />
          </div>
        ) : filteredDocs.length === 0 ? (
          <div className="text-center py-20 bg-slate-900/40 border border-slate-800/80 rounded-2xl">
            <ShieldCheck className="w-12 h-12 text-slate-600 mx-auto mb-3" />
            <h3 className="text-lg font-medium text-slate-300">İncelenecek Belge Bulunamadı</h3>
            <p className="text-xs text-slate-500 mt-1">
              Seçili filtre ve arama kriterlerine uygun belge kaydı yok.
            </p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {filteredDocs.map((doc) => {
              const info = getDocTypeInfo(doc.document_type);
              const isBusy = busyDocId === doc.id;

              return (
                <div
                  key={doc.id}
                  className="bg-slate-900/90 border border-slate-800 rounded-2xl p-6 flex flex-col justify-between hover:border-slate-700 transition shadow-lg"
                >
                  <div>
                    {/* Top Header: Provider Info & Status */}
                    <div className="flex items-start justify-between gap-4 border-b border-slate-800/80 pb-4">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-full bg-amber-500/10 border border-amber-500/30 flex items-center justify-center text-amber-400">
                          <User className="w-5 h-5" />
                        </div>
                        <div>
                          <h2 className="text-base font-bold text-slate-100">
                            {doc.provider?.user?.full_name || 'Hizmet Sağlayıcı'}
                          </h2>
                          <div className="flex items-center gap-2 text-xs text-slate-400 mt-0.5">
                            <span className="px-2 py-0.5 bg-slate-800 rounded text-amber-300/90 font-medium">
                              {doc.provider?.provider_type === 'chef'
                                ? 'Özel Şef'
                                : 'Barmen / Miksolojist'}
                            </span>
                            <span>•</span>
                            <span>{doc.provider?.user?.email}</span>
                          </div>
                        </div>
                      </div>

                      {/* Status Badge */}
                      <div className="flex flex-col items-end gap-1">
                        {doc.status === 'pending' && (
                          <span className="inline-flex items-center gap-1.5 px-3 py-1 bg-amber-500/10 border border-amber-500/30 text-amber-400 text-xs font-semibold rounded-full">
                            <Clock className="w-3.5 h-3.5" />
                            Bekliyor
                          </span>
                        )}
                        {doc.status === 'approved' && (
                          <span className="inline-flex items-center gap-1.5 px-3 py-1 bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 text-xs font-semibold rounded-full">
                            <CheckCircle className="w-3.5 h-3.5" />
                            Onaylandı
                          </span>
                        )}
                        {doc.status === 'rejected' && (
                          <span className="inline-flex items-center gap-1.5 px-3 py-1 bg-rose-500/10 border border-rose-500/30 text-rose-400 text-xs font-semibold rounded-full">
                            <XCircle className="w-3.5 h-3.5" />
                            Reddedildi
                          </span>
                        )}
                      </div>
                    </div>

                    {/* Document Type Details */}
                    <div className="mt-4 space-y-3">
                      <div className="flex items-center justify-between bg-slate-950/60 p-3.5 rounded-xl border border-slate-800/60">
                        <div>
                          <div className="flex items-center gap-2 text-slate-100 text-sm font-bold">
                            <Award className="w-4 h-4 text-amber-400" />
                            {info.label}
                          </div>
                          <div
                            className={`text-[11px] font-semibold mt-0.5 ${
                              info.isMandatory ? 'text-rose-400' : 'text-teal-400'
                            }`}
                          >
                            {info.tier}
                          </div>
                        </div>
                        <div className="text-xs text-slate-500">
                          {new Date(doc.created_at).toLocaleDateString('tr-TR')}
                        </div>
                      </div>

                      {/* Active Provider Verification Badges Preview */}
                      <div className="flex flex-wrap items-center gap-2 text-xs text-slate-400 px-1">
                        <span>Aktif Rozetler:</span>
                        {doc.provider?.is_verified ? (
                          <span className="px-2 py-0.5 rounded bg-emerald-500/10 text-emerald-400 font-semibold">
                            ✓ Onaylı Profil
                          </span>
                        ) : (
                          <span className="text-slate-500">Kimlik Bekliyor</span>
                        )}
                        {doc.provider?.verification_badges?.hygiene_cert && (
                          <span className="px-2 py-0.5 rounded bg-teal-500/10 text-teal-300 font-semibold">
                            ✓ Hijyen Sertifikalı
                          </span>
                        )}
                        {doc.provider?.verification_badges?.diploma && (
                          <span className="px-2 py-0.5 rounded bg-amber-500/10 text-amber-300 font-semibold">
                            ✓ Diplomalı Şef
                          </span>
                        )}
                      </div>

                      {doc.status === 'rejected' && doc.rejection_reason && (
                        <div className="bg-rose-950/40 border border-rose-800/60 p-3 rounded-xl text-rose-300 text-xs flex items-start gap-2">
                          <AlertTriangle className="w-4 h-4 text-rose-400 shrink-0 mt-0.5" />
                          <div>
                            <span className="font-bold">Red Gerekçesi: </span>
                            {doc.rejection_reason}
                          </div>
                        </div>
                      )}
                    </div>
                  </div>

                  {/* Bottom Action Footer */}
                  <div className="mt-6 pt-4 border-t border-slate-800/80 flex items-center justify-between gap-3">
                    <button
                      onClick={() => setPreviewUrl(doc.file_url)}
                      className="flex items-center gap-1.5 px-3 py-2 bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-medium rounded-lg transition cursor-pointer"
                    >
                      <Eye className="w-4 h-4 text-slate-400" />
                      Belgeyi İncele
                    </button>

                    <div className="flex items-center gap-2">
                      {doc.status !== 'rejected' && (
                        <button
                          disabled={isBusy}
                          onClick={() => setSelectedDocForReject(doc)}
                          className="flex items-center gap-1 px-3 py-2 bg-rose-500/10 hover:bg-rose-500/20 text-rose-400 border border-rose-500/30 text-xs font-semibold rounded-lg transition cursor-pointer"
                        >
                          <XCircle className="w-4 h-4" />
                          Reddet
                        </button>
                      )}

                      {doc.status !== 'approved' && (
                        <button
                          disabled={isBusy}
                          onClick={() => handleApprove(doc)}
                          className="flex items-center gap-1 px-4 py-2 bg-emerald-500 hover:bg-emerald-600 text-slate-950 text-xs font-bold rounded-lg transition shadow-md cursor-pointer"
                        >
                          <CheckCircle className="w-4 h-4" />
                          Onayla & Rozet Tanımla
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

      {/* Reject Modal Dialog */}
      {selectedDocForReject && (
        <div className="fixed inset-0 bg-slate-950/80 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl max-w-md w-full p-6 shadow-2xl space-y-4">
            <div className="flex items-center gap-3 text-rose-400">
              <AlertTriangle className="w-6 h-6" />
              <h3 className="text-lg font-bold text-slate-100">Belgeyi Reddet</h3>
            </div>

            <p className="text-xs text-slate-400">
              <span className="font-semibold text-slate-200">
                {selectedDocForReject.provider?.user?.full_name}
              </span>{' '}
              isimli sağlayıcının{' '}
              <span className="font-semibold text-amber-300">
                {getDocTypeInfo(selectedDocForReject.document_type).label}
              </span>{' '}
              belgesini reddetmek üzeresiniz. Red gerekçesi sağlayıcıya iletilecektir:
            </p>

            <textarea
              rows={4}
              placeholder="Örnek: Belge okunaksız veya son geçerlilik tarihi dolmuş."
              value={rejectReason}
              onChange={(e) => setRejectReason(e.target.value)}
              className="w-full bg-slate-950 border border-slate-800 focus:border-rose-500 rounded-xl p-3 text-xs text-slate-200 focus:outline-none transition resize-none"
            />

            <div className="flex items-center justify-end gap-3 pt-2">
              <button
                onClick={() => {
                  setSelectedDocForReject(null);
                  setRejectReason('');
                }}
                className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs font-medium rounded-lg transition"
              >
                İptal
              </button>

              <button
                onClick={handleConfirmReject}
                className="px-4 py-2 bg-rose-500 hover:bg-rose-600 text-slate-950 text-xs font-bold rounded-lg transition"
              >
                Reddi Onayla
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Document Preview Modal */}
      {previewUrl && (
        <div className="fixed inset-0 bg-slate-950/90 backdrop-blur-md flex items-center justify-center p-4 z-50">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl max-w-3xl w-full p-4 flex flex-col space-y-4 max-h-[90vh]">
            <div className="flex items-center justify-between border-b border-slate-800 pb-3">
              <h3 className="text-sm font-bold text-slate-200">Belge Önizleme</h3>
              <div className="flex items-center gap-2">
                <a
                  href={previewUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex items-center gap-1 text-xs text-amber-400 hover:underline mr-3"
                >
                  <ExternalLink className="w-3.5 h-3.5" />
                  Yeni Sekmede Aç
                </a>
                <button
                  onClick={() => setPreviewUrl(null)}
                  className="px-3 py-1 bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs rounded-lg"
                >
                  Kapat
                </button>
              </div>
            </div>

            <div className="flex-1 overflow-auto rounded-xl border border-slate-800 flex items-center justify-center bg-slate-950 p-4">
              {previewUrl.toLowerCase().endsWith('.pdf') ? (
                <div className="text-center space-y-3 py-12">
                  <FileText className="w-12 h-12 text-amber-400 mx-auto" />
                  <p className="text-xs text-slate-300 font-medium">{previewUrl}</p>
                  <a
                    href={previewUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-1.5 px-4 py-2 bg-amber-500 text-slate-950 rounded-lg text-xs font-bold"
                  >
                    <ExternalLink className="w-3.5 h-3.5" /> PDF Dosyasını Görüntüle
                  </a>
                </div>
              ) : (
                <img
                  src={previewUrl}
                  alt="Belge Önizleme"
                  className="max-h-[60vh] object-contain rounded-lg"
                />
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
