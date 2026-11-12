import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://wjtydxptgnciuneuylaf.supabase.co';
const supabaseAnonKey =
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndqdHlkeHB0Z25jaXVuZXV5bGFmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODcwNTcyMTIsImV4cCI6MjEwMjYzMzIxMn0.yWd033XfkgayuqFlcMOXDCIC9UaTRMQyH_zheqhnB98';

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
  },
});

export const DEFAULT_COMMISSION_RATE = 0.10; // %10 Platform Komisyonu, %90 Şef/Barmen Hakedişi

export type UserRole = 'customer' | 'chef' | 'bartender' | 'admin';

export interface UserProfile {
  id: string;
  email: string;
  full_name: string;
  first_name?: string | null;
  last_name?: string | null;
  phone?: string | null;
  avatar_url?: string | null;
  role: UserRole;
  default_address?: string | null;
  preferred_language?: string;
  preferred_currency?: string;
  created_at?: string;
}

export interface ProviderProfile {
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
  min_guests: number;
  max_guests: number;
  specialties?: {
    cuisines?: string[];
    dietary?: string[];
    cocktails?: string[];
  };
  equipment?: {
    has_bar_tools?: boolean;
    has_mobile_bar?: boolean;
    transportation_mode?: string;
  };
  portfolio_images?: string[];
  onboarding_status: 'draft' | 'pending_approval' | 'approved' | 'rejected' | 'suspended';
  rejection_reason?: string | null;
  is_verified: boolean;
  is_available_now: boolean;
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
  completed_bookings_count: number;
  user?: UserProfile;
}

export interface NotificationItem {
  id: string;
  user_id: string;
  booking_id?: string | null;
  title: string;
  body: string;
  notification_type: string;
  is_read: boolean;
  created_at: string;
}

export interface DemoAccountPreset {
  id: string;
  email: string;
  fullName: string;
  role: UserRole;
  badge: string;
  description: string;
  redirectPath: string;
}

export const DEMO_ACCOUNTS: DemoAccountPreset[] = [
  {
    id: '11111111-2222-4333-8444-555555550006',
    email: 'musteri@gastrohost.app',
    fullName: 'Elif Demir',
    role: 'customer',
    badge: 'VIP Müşteri',
    description: 'Aktif rezervasyonu (GH-99104), canlı şef takibi ve sohbet geçmişi olan müşteri hesabı',
    redirectPath: '/',
  },
  {
    id: '11111111-2222-4333-8444-555555550001',
    email: 'julian.vance@gastrohost.app',
    fullName: 'Şef Julian Vance',
    role: 'chef',
    badge: 'Fine Dining Şef',
    description: 'Onaylı özel şef; menüleri, takvimi, aktif rezervasyonları ve Escrow cüzdanı hazır',
    redirectPath: '/chef-dashboard',
  },
  {
    id: '11111111-2222-4333-8444-555555550003',
    email: 'marcus.thorne@gastrohost.app',
    fullName: 'Marcus Thorne',
    role: 'bartender',
    badge: 'Master Miksolojist',
    description: 'Onaylı barmen & kokteyl uzmanı; saatlik bar ve kokteyl paketleri yönetimi',
    redirectPath: '/chef-dashboard',
  },
  {
    id: '11111111-2222-4333-8444-555555550005',
    email: 'admin@gastrohost.app',
    fullName: 'GastroHost Admin',
    role: 'admin',
    badge: 'Sistem Yöneticisi',
    description: 'Belge & rozet onaylama, şef başvuruları, %10 komisyon ve Escrow ödeme yönetimi',
    redirectPath: '/admin',
  },
];
