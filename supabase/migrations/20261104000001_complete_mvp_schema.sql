-- ============================================================================
-- GASTROHOST (getir_chef) - COMPLETE MVP DATABASE SCHEMA, TRIGGERS, RPCS & RLS
-- Synced with Supabase Project: wjtydxptgnciuneuylaf (PostgreSQL 17 + PostGIS)
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS postgis;

-- 1. PROFILES TABLE
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS first_name TEXT,
  ADD COLUMN IF NOT EXISTS last_name TEXT,
  ADD COLUMN IF NOT EXISTS birth_date DATE,
  ADD COLUMN IF NOT EXISTS default_address TEXT,
  ADD COLUMN IF NOT EXISTS default_location GEOGRAPHY(Point, 4326),
  ADD COLUMN IF NOT EXISTS fcm_token TEXT,
  ADD COLUMN IF NOT EXISTS preferred_language TEXT DEFAULT 'tr',
  ADD COLUMN IF NOT EXISTS preferred_currency TEXT DEFAULT 'TRY',
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE public.profiles
  ALTER COLUMN full_name SET DEFAULT '';

-- 2. PROVIDER_PROFILES TABLE
ALTER TABLE public.provider_profiles
  ADD COLUMN IF NOT EXISTS title TEXT,
  ADD COLUMN IF NOT EXISTS current_step INTEGER DEFAULT 1,
  ADD COLUMN IF NOT EXISTS verification_badges JSONB DEFAULT '{"identity": false, "criminal_record": false, "hygiene_cert": false, "diploma": false}'::jsonb,
  ADD COLUMN IF NOT EXISTS wallet_balance NUMERIC(12, 2) DEFAULT 0.00,
  ADD COLUMN IF NOT EXISTS pending_escrow NUMERIC(12, 2) DEFAULT 0.00,
  ADD COLUMN IF NOT EXISTS hourly_rate NUMERIC(10, 2) DEFAULT 850.00,
  ADD COLUMN IF NOT EXISTS min_guests INTEGER DEFAULT 2,
  ADD COLUMN IF NOT EXISTS max_guests INTEGER DEFAULT 20,
  ADD COLUMN IF NOT EXISTS city_region TEXT DEFAULT 'İstanbul',
  ADD COLUMN IF NOT EXISTS portfolio_images TEXT[] DEFAULT '{}'::text[],
  ADD COLUMN IF NOT EXISTS is_available_now BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS rejection_reason TEXT,
  ADD COLUMN IF NOT EXISTS completed_bookings_count INTEGER DEFAULT 0;

ALTER TABLE public.provider_profiles
  ALTER COLUMN specialties SET DEFAULT '{"cuisines": [], "dietary": [], "cocktails": []}'::jsonb;

-- 3. PROVIDER_DOCUMENTS TABLE
ALTER TABLE public.provider_documents
  ADD COLUMN IF NOT EXISTS reviewed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMPTZ;

-- 4. PROVIDER_AVAILABILITY TABLE
ALTER TABLE public.provider_availability
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

CREATE UNIQUE INDEX IF NOT EXISTS idx_provider_availability_weekly
  ON public.provider_availability(provider_id, day_of_week)
  WHERE specific_date IS NULL AND day_of_week IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_provider_availability_date
  ON public.provider_availability(provider_id, specific_date)
  WHERE specific_date IS NOT NULL;

-- 5. MENUS TABLE
ALTER TABLE public.menus
  ADD COLUMN IF NOT EXISTS pricing_type TEXT DEFAULT 'per_person' CHECK (pricing_type IN ('per_person', 'hourly', 'fixed_package')),
  ADD COLUMN IF NOT EXISTS prep_time_minutes INTEGER DEFAULT 120,
  ADD COLUMN IF NOT EXISTS procurement_items JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS dietary_tags TEXT[] DEFAULT '{}'::text[],
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- 6. BOOKINGS TABLE
ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS booking_code TEXT UNIQUE,
  ADD COLUMN IF NOT EXISTS is_hourly BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS hours_count INTEGER DEFAULT 3,
  ADD COLUMN IF NOT EXISTS unit_price NUMERIC(10, 2) DEFAULT 0.00,
  ADD COLUMN IF NOT EXISTS commission_rate NUMERIC(4, 2) DEFAULT 0.15,
  ADD COLUMN IF NOT EXISTS ingredients_included BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS procurement_items JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS addon_bartender_id UUID REFERENCES public.provider_profiles(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS addon_menu_id UUID REFERENCES public.menus(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS addon_price NUMERIC(10, 2) DEFAULT 0.00,
  ADD COLUMN IF NOT EXISTS notes TEXT,
  ADD COLUMN IF NOT EXISTS cancel_reason TEXT,
  ADD COLUMN IF NOT EXISTS cancelled_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS accepted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- 7. PAYMENTS TABLE
ALTER TABLE public.payments
  ADD COLUMN IF NOT EXISTS customer_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS provider_id UUID REFERENCES public.provider_profiles(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS currency TEXT DEFAULT 'TRY',
  ADD COLUMN IF NOT EXISTS gateway TEXT DEFAULT 'iyzico',
  ADD COLUMN IF NOT EXISTS commission_rate NUMERIC(4, 2) DEFAULT 0.15,
  ADD COLUMN IF NOT EXISTS platform_fee NUMERIC(10, 2) DEFAULT 0.00,
  ADD COLUMN IF NOT EXISTS provider_payout NUMERIC(10, 2) DEFAULT 0.00,
  ADD COLUMN IF NOT EXISTS cancel_reason TEXT,
  ADD COLUMN IF NOT EXISTS auto_release_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS released_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS refunded_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

CREATE UNIQUE INDEX IF NOT EXISTS idx_payments_booking_id_unique ON public.payments(booking_id);

-- 8. MESSAGES TABLE
ALTER TABLE public.messages
  ADD COLUMN IF NOT EXISTS sender_role TEXT DEFAULT 'customer' CHECK (sender_role IN ('customer', 'chef', 'bartender', 'admin', 'system')),
  ADD COLUMN IF NOT EXISTS attachment_url TEXT,
  ADD COLUMN IF NOT EXISTS delivery_status TEXT DEFAULT 'sent' CHECK (delivery_status IN ('sent', 'delivered', 'read')),
  ADD COLUMN IF NOT EXISTS read_at TIMESTAMPTZ;

-- 9. REVIEWS TABLE
ALTER TABLE public.reviews
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

CREATE UNIQUE INDEX IF NOT EXISTS idx_reviews_booking_id_unique ON public.reviews(booking_id);

-- 10. WALLET_TRANSACTIONS & NOTIFICATIONS TABLES
CREATE TABLE IF NOT EXISTS public.wallet_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID NOT NULL REFERENCES public.provider_profiles(id) ON DELETE CASCADE,
  booking_id UUID REFERENCES public.bookings(id) ON DELETE SET NULL,
  payment_id UUID REFERENCES public.payments(id) ON DELETE SET NULL,
  transaction_type TEXT NOT NULL CHECK (transaction_type IN ('escrow_hold', 'escrow_release', 'escrow_refund', 'payout_withdrawal')),
  amount NUMERIC(10, 2) NOT NULL,
  status TEXT DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'cancelled')),
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  booking_id UUID REFERENCES public.bookings(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  notification_type TEXT DEFAULT 'general',
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.wallet_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- 11. FOREIGN KEY INDEXES
CREATE INDEX IF NOT EXISTS idx_bookings_customer_id ON public.bookings(customer_id);
CREATE INDEX IF NOT EXISTS idx_bookings_provider_id ON public.bookings(provider_id);
CREATE INDEX IF NOT EXISTS idx_bookings_menu_id ON public.bookings(menu_id);
CREATE INDEX IF NOT EXISTS idx_bookings_addon_bartender_id ON public.bookings(addon_bartender_id);
CREATE INDEX IF NOT EXISTS idx_bookings_addon_menu_id ON public.bookings(addon_menu_id);
CREATE INDEX IF NOT EXISTS idx_bookings_cancelled_by ON public.bookings(cancelled_by);
CREATE INDEX IF NOT EXISTS idx_bookings_status_event_date ON public.bookings(status, event_date);
CREATE INDEX IF NOT EXISTS idx_menus_provider_id ON public.menus(provider_id);
CREATE INDEX IF NOT EXISTS idx_messages_booking_id ON public.messages(booking_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_payments_booking_id ON public.payments(booking_id);
CREATE INDEX IF NOT EXISTS idx_payments_customer_id ON public.payments(customer_id);
CREATE INDEX IF NOT EXISTS idx_payments_provider_id ON public.payments(provider_id);
CREATE INDEX IF NOT EXISTS idx_reviews_booking_id ON public.reviews(booking_id);
CREATE INDEX IF NOT EXISTS idx_reviews_customer_id ON public.reviews(customer_id);
CREATE INDEX IF NOT EXISTS idx_reviews_provider_id ON public.reviews(provider_id);
CREATE INDEX IF NOT EXISTS idx_provider_documents_reviewed_by ON public.provider_documents(reviewed_by);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_provider_id ON public.wallet_transactions(provider_id);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_booking_id ON public.wallet_transactions(booking_id);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_payment_id ON public.wallet_transactions(payment_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_booking_id ON public.notifications(booking_id);

