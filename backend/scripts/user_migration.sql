-- Migration: Separate User Profiles

-- 1. Create admin_profiles table
CREATE TABLE IF NOT EXISTS public.admin_profiles (
    id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
    permissions JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create customer_profiles table (formerly just 'user' role)
CREATE TABLE IF NOT EXISTS public.customer_profiles (
    id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
    phone TEXT,
    address TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Ensure vendors table is correctly linked to users (already exists, but check consistency)
-- ALTER TABLE public.vendors ADD CONSTRAINT fk_vendor_owner FOREIGN KEY (owner_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- 4. Migration: Populate existing profiles based on roles
-- Populate admin_profiles
INSERT INTO public.admin_profiles (id)
SELECT id FROM public.users WHERE role = 'admin'
ON CONFLICT (id) DO NOTHING;

-- Populate customer_profiles
INSERT INTO public.customer_profiles (id)
SELECT id FROM public.users WHERE role = 'user'
ON CONFLICT (id) DO NOTHING;

-- 5. RLS Policies for new tables
ALTER TABLE public.admin_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customer_profiles ENABLE ROW LEVEL SECURITY;

-- Admin can see all profiles
CREATE POLICY "Admins can view all admin profiles" ON public.admin_profiles FOR SELECT TO authenticated USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
);

CREATE POLICY "Admins can view all customer profiles" ON public.customer_profiles FOR SELECT TO authenticated USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
);

-- Users can see their own profiles
CREATE POLICY "Users can view own admin profile" ON public.admin_profiles FOR SELECT TO authenticated USING (id = auth.uid());
CREATE POLICY "Users can view own customer profile" ON public.customer_profiles FOR SELECT TO authenticated USING (id = auth.uid());

-- Users can update their own profiles
CREATE POLICY "Users can update own customer profile" ON public.customer_profiles FOR UPDATE TO authenticated USING (id = auth.uid());
