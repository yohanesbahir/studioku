-- SUPABASE SQL SCHEMA FOR STUDIOKU

-- 1. Enums
CREATE TYPE user_role AS ENUM ('user', 'admin');
CREATE TYPE user_plan AS ENUM ('free', 'pro', 'premium');
CREATE TYPE order_status AS ENUM ('PENDING', 'PAID', 'EXPIRED', 'FAILED');
CREATE TYPE commission_status AS ENUM ('pending', 'available', 'paid', 'cancelled');
CREATE TYPE payout_status AS ENUM ('pending', 'approved', 'rejected');

-- 2. Profiles Table
CREATE TABLE public.profiles (
  id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  plan user_plan DEFAULT 'free'::user_plan,
  plan_activated_at TIMESTAMPTZ,
  credits_balance INTEGER DEFAULT 0,
  referral_code TEXT UNIQUE,
  referred_by TEXT,
  role user_role DEFAULT 'user'::user_role,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Plans & Coupons
CREATE TABLE public.plans (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  price INTEGER NOT NULL,
  monthly_credits INTEGER NOT NULL,
  is_active BOOLEAN DEFAULT true
);

INSERT INTO public.plans (id, name, price, monthly_credits) VALUES 
  ('pro', 'Paket Pro', 99000, 300),
  ('premium', 'Paket Premium', 149000, 600);

CREATE TABLE public.coupons (
  code TEXT PRIMARY KEY,
  discount_type TEXT NOT NULL,
  discount_value INTEGER NOT NULL,
  max_uses INTEGER DEFAULT 100,
  times_used INTEGER DEFAULT 0,
  expires_at TIMESTAMPTZ
);

-- 4. Orders
CREATE TABLE public.orders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  email TEXT NOT NULL,
  plan_id TEXT REFERENCES public.plans(id),
  amount INTEGER NOT NULL,
  status order_status DEFAULT 'PENDING'::order_status,
  provider TEXT DEFAULT 'xendit',
  provider_ref TEXT,
  coupon_code TEXT REFERENCES public.coupons(code),
  referral_code TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  paid_at TIMESTAMPTZ
);

-- 5. Audit & Logs
CREATE TABLE public.payments_log (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  order_id UUID REFERENCES public.orders(id),
  event_type TEXT NOT NULL,
  raw_payload JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.audit_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  action TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Features & AI Tracking
CREATE TABLE public.features (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  credit_cost INTEGER NOT NULL DEFAULT 1,
  required_plan user_plan DEFAULT 'free'::user_plan,
  is_active BOOLEAN DEFAULT true
);

INSERT INTO public.features (id, name, credit_cost, required_plan) VALUES 
  ('remove_bg', 'Hapus Background', 1, 'pro'),
  ('headshot', 'Headshot Profesional', 5, 'pro'),
  ('video_gen', 'Video AI', 15, 'premium');

CREATE TABLE public.generations_log (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  feature_id TEXT REFERENCES public.features(id),
  credits_used INTEGER NOT NULL,
  provider_cost_usd NUMERIC(10, 5) NOT NULL,
  status TEXT DEFAULT 'completed',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.jobs_queue (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  feature_id TEXT REFERENCES public.features(id),
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Creations & Gallery
CREATE TABLE public.creations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  feature_id TEXT REFERENCES public.features(id),
  original_image_url TEXT,
  result_url TEXT NOT NULL,
  prompt TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. Affiliate System
CREATE TABLE public.commissions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  referrer_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  referred_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  order_id UUID REFERENCES public.orders(id),
  amount INTEGER NOT NULL,
  status commission_status DEFAULT 'pending'::commission_status,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  available_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '7 days'
);

CREATE TABLE public.payout_requests (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  amount INTEGER NOT NULL,
  bank_name TEXT NOT NULL,
  account_number TEXT NOT NULL,
  account_name TEXT NOT NULL,
  status payout_status DEFAULT 'pending'::payout_status,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  processed_at TIMESTAMPTZ
);
