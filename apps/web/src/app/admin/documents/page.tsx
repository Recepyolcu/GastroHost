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
  Eye
} from 'lucide-react';

interface DocumentItem {
  id: string;
  provider_id: string;
  document_type: 'identity' | 'criminal_record' | 'hygiene_cert' | 'diploma' | 'portfolio' | 'other';
  file_url: string;
  status: 'pending' | 'approved' | 'rejected';
  rejection_reason?: string | null;
  created_at: string;
  provider?: {
    id: string;
    provider_type: string;
    is_verified: boolean;
    verification_badges: {
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

// Mock initial data for fallback/demo
const MOCK_DOCUMENTS: DocumentItem[] = [
  {
    id: 'doc-101',
    provider_id: 'prov-001',
    document_type: 'identity',
    file_url: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=600&q=80',
    status: 'pending',
    created_at: new Date(Date.now() - 3600000 * 4).toISOString(),
    provider: {
      id: 'prov-001',
      provider_type: 'chef',
      is_verified: false,
      verification_badges: { hygiene_cert: false, diploma: false },
      user: {
        full_name: 'Şef Mehmet Yılmaz',
        email: 'mehmet.chef@gastrohost.com',
        phone: '+90 532 111 2233'
      }
    }
  },
  {
    id: 'doc-102',
    provider_id: 'prov-001',
    document_type: 'hygiene_cert',
    file_url: 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&w=600&q=80',
    status: 'pending',
    created_at: new Date(Date.now() - 3600000 * 3).toISOString(),
    provider: {
      id: 'prov-001',
      provider_type: 'chef',
      is_verified: false,
      verification_badges: { hygiene_cert: false, diploma: false },
      user: {
        full_name: 'Şef Mehmet Yılmaz',
        email: 'mehmet.chef@gastrohost.com',
        phone: '+90 532 111 2233'
      }
    }
  },
  {
    id: 'doc-103',
    provider_id: 'prov-002',
    document_type: 'diploma',
    file_url: 'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?auto=format&fit=crop&w=600&q=80',
    status: 'approved',
    created_at: new Date(Date.now() - 3600000 * 24).toISOString(),
    provider: {
      id: 'prov-002',
      provider_type: 'chef',
      is_verified: true,
      verification_badges: { hygiene_cert: true, diploma: true },
      user: {
        full_name: 'Şef Ayşe Kaya (Mutfak Akademisi)',
        email: 'ayse.kaya@gastrohost.com',
        phone: '+90 535 444 5566'
      }
    }
  },
  {
    id: 'doc-104',
    provider_id: 'prov-003',
    document_type: 'hygiene_cert',
    file_url: 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?auto=format&fit=crop&w=600&q=80',
    status: 'rejected',
    rejection_reason: 'Sertifikanın son geçerlilik tarihi dolmuş, lütfen güncel belge yükleyiniz.',
    created_at: new Date(Date.now() - 3600000 * 48).toISOString(),
    provider: {
      id: 'prov-003',
      provider_type: 'bartender',
      is_verified: true,
      verification_badges: { hygiene_cert: false, diploma: false },
      user: {
        full_name: 'Barmen Can Demir',
        email: 'can.mixology@gastrohost.com',
        phone: '+90 542 777 8899'
      }
    }
  }
];

export default function AdminDocumentsPage() {
  const [documents, setDocuments] = useState<DocumentItem[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [filterStatus, setFilterStatus] = useState<'all' | 'pending' | 'approved' | 'rejected'>('pending');
  const [searchTerm, setSearchTerm] = useState<string>('');
  
  // Rejection modal state
  const [selectedDocForReject, setSelectedDocForReject] = useState<DocumentItem | null>(null);
  const [rejectReason, setRejectReason] = useState<string>('');

  // Preview modal state
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);

  const fetchDocuments = async () => {
    setLoading(true);
    try {
      // Query Supabase provider_documents with provider profiles
      const { data, error } = await supabase
        .from('provider_documents')
        .select(`
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
        `)
        .order('created_at', { ascending: false });

      if (error || !data || data.length === 0) {
        console.log('Supabase fetch notice: using fallback/demo document data');
        setDocuments(MOCK_DOCUMENTS);
      } else {
        setDocuments(data as unknown as DocumentItem[]);
      }
    } catch (e) {
      console.error('Error fetching documents:', e);
      setDocuments(MOCK_DOCUMENTS);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDocuments();
  }, []);

  // Handle Document Approval
  const handleApprove = async (doc: DocumentItem) => {
    try {
      // Try RPC function first
      const { error } = await supabase.rpc('admin_review_document', {
        doc_id: doc.id,
        new_status: 'approved',
        reason: null
      });

      if (error) {
        // Fallback directly updating table if RPC fails or not migrated yet
        await supabase
          .from('provider_documents')
          .update({ status: 'approved', rejection_reason: null })
          .eq('id', doc.id);
      }

      // Update state locally
      setDocuments(prev => prev.map(item => {
        if (item.id === doc.id) {
          const updatedBadges = { ...(item.provider?.verification_badges || {}) };
          if (doc.document_type === 'hygiene_cert') updatedBadges.hygiene_cert = true;
          if (doc.document_type === 'diploma') updatedBadges.diploma = true;
          
          return {
            ...item,
            status: 'approved',
            rejection_reason: null,
            provider: item.provider ? {
              ...item.provider,
              is_verified: doc.document_type === 'identity' ? true : item.provider.is_verified,
              verification_badges: updatedBadges
            } : undefined
          };
        }
        return item;
      }));
    } catch (e) {
      console.error('Approve error:', e);
    }
  };

  // Handle Document Rejection
  const handleConfirmReject = async () => {
    if (!selectedDocForReject) return;

    const doc = selectedDocForReject;
    const reason = rejectReason.trim() || 'Yüklenen belge geçerlilik standartlarını karşılamıyor.';

    try {
      const { error } = await supabase.rpc('admin_review_document', {
        doc_id: doc.id,
        new_status: 'rejected',
        reason: reason
      });

      if (error) {
        await supabase
          .from('provider_documents')
          .update({ status: 'rejected', rejection_reason: reason })
          .eq('id', doc.id);
      }

      setDocuments(prev => prev.map(item => {
        if (item.id === doc.id) {
          const updatedBadges = { ...(item.provider?.verification_badges || {}) };
          if (doc.document_type === 'hygiene_cert') updatedBadges.hygiene_cert = false;
          if (doc.document_type === 'diploma') updatedBadges.diploma = false;

          return {
            ...item,
            status: 'rejected',
            rejection_reason: reason,
            provider: item.provider ? {
              ...item.provider,
              is_verified: doc.document_type === 'identity' ? false : item.provider.is_verified,
              verification_badges: updatedBadges
            } : undefined
          };
        }
        return item;
      }));

      setSelectedDocForReject(null);
      setRejectReason('');
    } catch (e) {
      console.error('Reject error:', e);
    }
  };

  const getDocTypeName = (type: string) => {
    switch (type) {
      case 'identity': return 'Kimlik / Adli Sicil';
      case 'criminal_record': return 'Adli Sicil Kaydı';
      case 'hygiene_cert': return 'Hijyen Eğitimi Sertifikası';
      case 'diploma': return 'Gastronomi / Aşçılık Diploması';
      case 'portfolio': return 'Portfolyo Görseli';
      default: return 'Diğer Belge';
    }
  };

  const filteredDocs = documents.filter(doc => {
    const matchesStatus = filterStatus === 'all' || doc.status === filterStatus;
    const providerName = doc.provider?.user?.full_name?.toLowerCase() || '';
    const docType = getDocTypeName(doc.document_type).toLowerCase();
    const matchesSearch = providerName.includes(searchTerm.toLowerCase()) || docType.includes(searchTerm.toLowerCase());
    return matchesStatus && matchesSearch;
  });

  const pendingCount = documents.filter(d => d.status === 'pending').length;
  const approvedCount = documents.filter(d => d.status === 'approved').length;
  const rejectedCount = documents.filter(d => d.status === 'rejected').length;

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 font-sans p-6 md:p-10">
      {/* Header */}
      <div className="max-w-7xl mx-auto space-y-8">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 border-b border-slate-800 pb-6">
          <div>
            <div className="flex items-center gap-3">
              <ShieldCheck className="w-9 h-9 text-amber-400" />
              <h1 className="text-3xl font-bold tracking-tight bg-gradient-to-r from-amber-200 via-orange-400 to-amber-500 bg-clip-text text-transparent">
                GastroHost Admin
              </h1>
            </div>
            <p className="text-slate-400 text-sm mt-1">
              Şef & Barmen Belge İnceleme ve Rozet Doğrulama Merkezi
            </p>
          </div>

          <div className="flex items-center gap-3">
            {/* Admin Navigation Tabs */}
            <div className="flex items-center gap-2 bg-slate-900 p-1 border border-slate-800 rounded-xl">
              <Link 
                href="/admin/documents"
                className="px-4 py-2 text-xs font-bold bg-amber-500 text-slate-950 rounded-lg shadow-sm"
              >
                Belge İnceleme
              </Link>
              <Link
                href="/admin/payments"
                className="px-4 py-2 text-xs font-semibold text-slate-400 hover:text-slate-200 hover:bg-slate-800/60 rounded-lg transition"
              >
                Escrow & Ödemeler
              </Link>
            </div>

            <button 
              onClick={fetchDocuments} 
              className="flex items-center gap-2 px-4 py-2 bg-slate-900 hover:bg-slate-800 border border-slate-700 rounded-lg text-slate-300 text-sm font-medium transition cursor-pointer"
            >
              <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
              Yenile
            </button>
          </div>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <div className="bg-slate-900/80 border border-slate-800 rounded-xl p-5 backdrop-blur">
            <div className="flex items-center justify-between text-slate-400 text-xs font-semibold uppercase tracking-wider">
              <span>Toplam Yüklenen</span>
              <FileText className="w-5 h-5 text-indigo-400" />
            </div>
            <div className="text-3xl font-bold mt-2 text-slate-100">{documents.length}</div>
          </div>

          <div 
            onClick={() => setFilterStatus('pending')}
            className={`cursor-pointer transition bg-slate-900/80 border rounded-xl p-5 backdrop-blur ${filterStatus === 'pending' ? 'ring-2 ring-amber-500 border-amber-500/50' : 'border-slate-800 hover:border-amber-500/30'}`}
          >
            <div className="flex items-center justify-between text-amber-400 text-xs font-semibold uppercase tracking-wider">
              <span>Inceleme Bekleyen</span>
              <Clock className="w-5 h-5" />
            </div>
            <div className="text-3xl font-bold mt-2 text-amber-400">{pendingCount}</div>
          </div>

          <div 
            onClick={() => setFilterStatus('approved')}
            className={`cursor-pointer transition bg-slate-900/80 border rounded-xl p-5 backdrop-blur ${filterStatus === 'approved' ? 'ring-2 ring-emerald-500 border-emerald-500/50' : 'border-slate-800 hover:border-emerald-500/30'}`}
          >
            <div className="flex items-center justify-between text-emerald-400 text-xs font-semibold uppercase tracking-wider">
              <span>Onaylanan Belgeler</span>
              <CheckCircle className="w-5 h-5" />
            </div>
            <div className="text-3xl font-bold mt-2 text-emerald-400">{approvedCount}</div>
          </div>

          <div 
            onClick={() => setFilterStatus('rejected')}
            className={`cursor-pointer transition bg-slate-900/80 border rounded-xl p-5 backdrop-blur ${filterStatus === 'rejected' ? 'ring-2 ring-rose-500 border-rose-500/50' : 'border-slate-800 hover:border-rose-500/30'}`}
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
            
            {(['all', 'pending', 'approved', 'rejected'] as const).map(status => (
              <button
                key={status}
                onClick={() => setFilterStatus(status)}
                className={`px-3 py-1.5 rounded-lg text-xs font-semibold capitalize transition ${
                  filterStatus === status
                    ? 'bg-amber-500 text-slate-950 font-bold'
                    : 'bg-slate-800/80 hover:bg-slate-800 text-slate-400'
                }`}
              >
                {status === 'all' && 'Tümü'}
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
              placeholder="Şef adı veya belge ara..."
              value={searchTerm}
              onChange={e => setSearchTerm(e.target.value)}
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
            <p className="text-xs text-slate-500 mt-1">Seçili filtre ve arama kriterlerine uygun belge kaydı yok.</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {filteredDocs.map(doc => (
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
                          {doc.provider?.user?.full_name || 'Bilinmeyen Hizmet Sağlayıcı'}
                        </h2>
                        <div className="flex items-center gap-2 text-xs text-slate-400 mt-0.5">
                          <span className="capitalize px-2 py-0.5 bg-slate-800 rounded text-amber-300/90 font-medium">
                            {doc.provider?.provider_type === 'chef' ? 'Özel Şef' : 'Barmen / Miksolojist'}
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
                    <div className="flex items-center justify-between bg-slate-950/60 p-3 rounded-xl border border-slate-800/60">
                      <div className="flex items-center gap-2 text-slate-300 text-sm font-semibold">
                        <Award className="w-4 h-4 text-amber-400" />
                        {getDocTypeName(doc.document_type)}
                      </div>
                      <div className="text-xs text-slate-500">
                        {new Date(doc.created_at).toLocaleDateString('tr-TR')}
                      </div>
                    </div>

                    {/* Active Provider Verification Badges Preview */}
                    <div className="flex items-center gap-2 text-xs text-slate-400 px-1">
                      <span>Mevcut Rozetler:</span>
                      {doc.provider?.is_verified ? (
                        <span className="text-emerald-400 font-medium">✓ Kimlik Doğrulanmış</span>
                      ) : (
                        <span className="text-slate-500">Kimlik Doğrulanmamış</span>
                      )}
                      {doc.provider?.verification_badges?.hygiene_cert && (
                        <span className="text-emerald-400 font-medium">✓ Hijyen Cert</span>
                      )}
                      {doc.provider?.verification_badges?.diploma && (
                        <span className="text-emerald-400 font-medium">✓ Diplomalı</span>
                      )}
                    </div>

                    {/* Rejection Reason if any */}
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
                    className="flex items-center gap-1.5 px-3 py-2 bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-medium rounded-lg transition"
                  >
                    <Eye className="w-4 h-4 text-slate-400" />
                    Belgeyi İncele
                  </button>

                  <div className="flex items-center gap-2">
                    {doc.status !== 'rejected' && (
                      <button
                        onClick={() => setSelectedDocForReject(doc)}
                        className="flex items-center gap-1 px-3 py-2 bg-rose-500/10 hover:bg-rose-500/20 text-rose-400 border border-rose-500/30 text-xs font-semibold rounded-lg transition"
                      >
                        <XCircle className="w-4 h-4" />
                        Reddet
                      </button>
                    )}

                    {doc.status !== 'approved' && (
                      <button
                        onClick={() => handleApprove(doc)}
                        className="flex items-center gap-1 px-4 py-2 bg-emerald-500 hover:bg-emerald-600 text-slate-950 text-xs font-bold rounded-lg transition shadow-md"
                      >
                        <CheckCircle className="w-4 h-4" />
                        Onayla
                      </button>
                    )}
                  </div>
                </div>
              </div>
            ))}
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
              <span className="font-semibold text-slate-200">{selectedDocForReject.provider?.user?.full_name}</span> isimli şefin <span className="font-semibold text-amber-300">{getDocTypeName(selectedDocForReject.document_type)}</span> belgesini reddetmek üzeresiniz. Red gerekçesi şefe iletilecektir:
            </p>

            <textarea
              rows={4}
              placeholder="Örnek: Belge okunaksız, son kullanma tarihi geçmiş veya sahte evrak şüphesi var."
              value={rejectReason}
              onChange={e => setRejectReason(e.target.value)}
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

            <div className="flex-1 overflow-auto rounded-xl border border-slate-800 flex items-center justify-center bg-slate-950 p-2">
              {previewUrl.toLowerCase().endsWith('.pdf') ? (
                <iframe src={previewUrl} className="w-full h-[60vh] rounded-lg" />
              ) : (
                <img src={previewUrl} alt="Belge Önizleme" className="max-h-[60vh] object-contain rounded-lg" />
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
