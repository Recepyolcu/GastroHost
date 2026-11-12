'use client';

import React, { createContext, useCallback, useContext, useEffect, useState } from 'react';
import {
  supabase,
  UserProfile,
  ProviderProfile,
  NotificationItem,
  UserRole,
  DEMO_ACCOUNTS,
} from '@/lib/supabase';

export interface CityLocation {
  label: string;
  lat: number;
  lng: number;
}

export const ISTANBUL_DISTRICTS: CityLocation[] = [
  { label: 'Kadıköy, İstanbul', lat: 40.9819, lng: 29.0254 },
  { label: 'Suadiye / Bağdat Cad., İstanbul', lat: 40.9614, lng: 29.0752 },
  { label: 'Beşiktaş, İstanbul', lat: 41.0682, lng: 29.0432 },
  { label: 'Şişli / Nişantaşı, İstanbul', lat: 41.0491, lng: 28.9942 },
  { label: 'Sarıyer, İstanbul', lat: 41.1086, lng: 29.0546 },
  { label: 'Üsküdar, İstanbul', lat: 41.0262, lng: 29.0151 },
  { label: 'Ataşehir, İstanbul', lat: 40.9923, lng: 29.1244 },
];

interface AuthContextValue {
  userProfile: UserProfile | null;
  providerProfile: ProviderProfile | null;
  notifications: NotificationItem[];
  unreadCount: number;
  loading: boolean;
  userLocation: CityLocation;
  setUserLocation: (loc: CityLocation) => void;
  activeCategory: string;
  setActiveCategory: (cat: string) => void;
  signInWithEmail: (email: string, password: string) => Promise<{ error?: string; profile?: UserProfile | null }>;
  signUpWithEmail: (
    email: string,
    password: string,
    fullName: string,
    role: UserRole,
    phone?: string
  ) => Promise<{ error?: string; profile?: UserProfile | null }>;
  signInWithGoogle: (role?: UserRole) => Promise<{ error?: string }>;
  signInWithDemoAccount: (email: string) => Promise<{ error?: string; profile?: UserProfile | null }>;
  signOut: () => Promise<void>;
  refreshProfile: () => Promise<void>;
  markNotificationAsRead: (id: string) => Promise<void>;
  markAllNotificationsAsRead: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

const DEMO_STORAGE_KEY = 'gastrohost_active_demo_email';

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [userProfile, setUserProfile] = useState<UserProfile | null>(null);
  const [providerProfile, setProviderProfile] = useState<ProviderProfile | null>(null);
  const [notifications, setNotifications] = useState<NotificationItem[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [userLocation, setUserLocation] = useState<CityLocation>(ISTANBUL_DISTRICTS[0]);
  const [activeCategory, setActiveCategory] = useState<string>('all');

  const loadUserAndProviderData = useCallback(async (userId: string) => {
    try {
      const [{ data: profileData }, { data: providerData }, { data: notifData }] = await Promise.all([
        supabase.from('profiles').select('*').eq('id', userId).maybeSingle(),
        supabase.from('provider_profiles').select('*').eq('user_id', userId).maybeSingle(),
        supabase
          .from('notifications')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', { ascending: false })
          .limit(15),
      ]);

      if (profileData) {
        setUserProfile(profileData as UserProfile);
      }
      setProviderProfile((providerData as ProviderProfile) || null);
      setNotifications((notifData as NotificationItem[]) || []);
      return (profileData as UserProfile) || null;
    } catch (e) {
      console.error('Error loading user profile:', e);
      return null;
    }
  }, []);

  const refreshProfile = useCallback(async () => {
    const {
      data: { session },
    } = await supabase.auth.getSession();

    if (session?.user?.id) {
      await loadUserAndProviderData(session.user.id);
      return;
    }

    // Fallback to persisted demo session if present
    if (typeof window !== 'undefined') {
      const savedDemoEmail = localStorage.getItem(DEMO_STORAGE_KEY);
      if (savedDemoEmail) {
        const preset = DEMO_ACCOUNTS.find((a) => a.email === savedDemoEmail);
        if (preset) {
          await loadUserAndProviderData(preset.id);
          return;
        }
      }
    }

    setUserProfile(null);
    setProviderProfile(null);
    setNotifications([]);
  }, [loadUserAndProviderData]);

  useEffect(() => {
    let mounted = true;

    const initAuth = async () => {
      setLoading(true);
      try {
        const {
          data: { session },
        } = await supabase.auth.getSession();

        if (session?.user?.id) {
          if (mounted) {
            await loadUserAndProviderData(session.user.id);
          }
        } else if (typeof window !== 'undefined') {
          const savedDemoEmail = localStorage.getItem(DEMO_STORAGE_KEY) || 'musteri@gastrohost.app';
          // Auto sign-in to default demo account if no session is active so RLS queries work out of the box
          const { data: signInData } = await supabase.auth.signInWithPassword({
            email: savedDemoEmail,
            password: 'GastroHost2026!',
          });
          if (signInData?.user?.id && mounted) {
            await loadUserAndProviderData(signInData.user.id);
          }
        }
      } catch (e) {
        console.error('Auth init error:', e);
      } finally {
        if (mounted) setLoading(false);
      }
    };

    initAuth();

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange(async (_event, session) => {
      if (!mounted) return;
      if (session?.user?.id) {
        await loadUserAndProviderData(session.user.id);
      } else {
        setUserProfile(null);
        setProviderProfile(null);
        setNotifications([]);
      }
    });

    return () => {
      mounted = false;
      subscription.unsubscribe();
    };
  }, [loadUserAndProviderData]);

  const signInWithEmail = async (email: string, password: string) => {
    const { data, error } = await supabase.auth.signInWithPassword({
      email: email.trim(),
      password,
    });
    if (error) {
      return { error: error.message };
    }
    if (typeof window !== 'undefined') {
      localStorage.removeItem(DEMO_STORAGE_KEY);
    }
    const profile = data.user ? await loadUserAndProviderData(data.user.id) : null;
    return { profile };
  };

  const signUpWithEmail = async (
    email: string,
    password: string,
    fullName: string,
    role: UserRole,
    phone?: string
  ) => {
    const { data, error } = await supabase.auth.signUp({
      email: email.trim(),
      password,
      options: {
        data: {
          full_name: fullName.trim(),
          role,
          phone: phone?.trim() || null,
        },
      },
    });
    if (error) {
      return { error: error.message };
    }
    if (data.user) {
      await supabase.from('profiles').upsert({
        id: data.user.id,
        email: email.trim(),
        full_name: fullName.trim(),
        role,
        phone: phone?.trim() || null,
      });
      const profile = await loadUserAndProviderData(data.user.id);
      return { profile };
    }
    return { profile: null };
  };

  const signInWithGoogle = async (role: UserRole = 'customer') => {
    if (typeof window !== 'undefined') {
      localStorage.setItem('gastrohost_oauth_preferred_role', role);
    }
    const redirectTo =
      typeof window !== 'undefined'
        ? `${window.location.origin}${role === 'chef' || role === 'bartender' ? '/chef-dashboard' : '/'}`
        : undefined;

    const { error } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo,
        queryParams: {
          access_type: 'offline',
          prompt: 'consent',
        },
      },
    });

    if (error) {
      return { error: error.message };
    }
    return {};
  };

  const signInWithDemoAccount = async (email: string) => {
    if (typeof window !== 'undefined') {
      localStorage.setItem(DEMO_STORAGE_KEY, email);
    }
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password: 'GastroHost2026!',
    });
    if (error) {
      return { error: error.message };
    }
    const profile = data.user ? await loadUserAndProviderData(data.user.id) : null;
    return { profile };
  };

  const signOut = async () => {
    if (typeof window !== 'undefined') {
      localStorage.removeItem(DEMO_STORAGE_KEY);
    }
    await supabase.auth.signOut();
    setUserProfile(null);
    setProviderProfile(null);
    setNotifications([]);
  };

  const markNotificationAsRead = async (id: string) => {
    await supabase.from('notifications').update({ is_read: true }).eq('id', id);
    setNotifications((prev) => prev.map((n) => (n.id === id ? { ...n, is_read: true } : n)));
  };

  const markAllNotificationsAsRead = async () => {
    if (!userProfile?.id) return;
    await supabase.from('notifications').update({ is_read: true }).eq('user_id', userProfile.id);
    setNotifications((prev) => prev.map((n) => ({ ...n, is_read: true })));
  };

  const unreadCount = notifications.filter((n) => !n.is_read).length;

  return (
    <AuthContext.Provider
      value={{
        userProfile,
        providerProfile,
        notifications,
        unreadCount,
        loading,
        userLocation,
        setUserLocation,
        activeCategory,
        setActiveCategory,
        signInWithEmail,
        signUpWithEmail,
        signInWithGoogle,
        signInWithDemoAccount,
        signOut,
        refreshProfile,
        markNotificationAsRead,
        markAllNotificationsAsRead,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return ctx;
}

