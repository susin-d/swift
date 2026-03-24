-- Add persisted vendor preference fields and staff management tables.
ALTER TABLE public.vendor_settings
    ADD COLUMN IF NOT EXISTS preferred_language TEXT DEFAULT 'English',
    ADD COLUMN IF NOT EXISTS theme_dark_mode BOOLEAN DEFAULT false,
    ADD COLUMN IF NOT EXISTS theme_high_contrast BOOLEAN DEFAULT false,
    ADD COLUMN IF NOT EXISTS app_compact_cards BOOLEAN DEFAULT false,
    ADD COLUMN IF NOT EXISTS app_silent_alerts BOOLEAN DEFAULT false,
    ADD COLUMN IF NOT EXISTS app_notification_enabled BOOLEAN DEFAULT true,
    ADD COLUMN IF NOT EXISTS app_auto_print_receipts BOOLEAN DEFAULT false;

CREATE TABLE IF NOT EXISTS public.vendor_staff_members (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    vendor_id UUID REFERENCES public.vendors(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    role_key TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
    email TEXT,
    phone TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(vendor_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.vendor_staff_invitations (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    vendor_id UUID REFERENCES public.vendors(id) ON DELETE CASCADE NOT NULL,
    invited_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    invited_user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    email TEXT NOT NULL,
    role_key TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'revoked', 'expired')),
    invite_token TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMP WITH TIME ZONE,
    accepted_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.vendor_staff_roles (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    vendor_id UUID REFERENCES public.vendors(id) ON DELETE CASCADE NOT NULL,
    role_key TEXT NOT NULL,
    permissions JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(vendor_id, role_key)
);

-- Rollback notes:
-- 1) DROP TABLE IF EXISTS public.vendor_staff_invitations;
-- 2) DROP TABLE IF EXISTS public.vendor_staff_roles;
-- 3) DROP TABLE IF EXISTS public.vendor_staff_members;
-- 4) ALTER TABLE public.vendor_settings
--      DROP COLUMN IF EXISTS app_auto_print_receipts,
--      DROP COLUMN IF EXISTS app_notification_enabled,
--      DROP COLUMN IF EXISTS app_silent_alerts,
--      DROP COLUMN IF EXISTS app_compact_cards,
--      DROP COLUMN IF EXISTS theme_high_contrast,
--      DROP COLUMN IF EXISTS theme_dark_mode,
--      DROP COLUMN IF EXISTS preferred_language;
