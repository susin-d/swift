-- Password reset OTP storage for Brevo-based forgot password flow.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS public.password_reset_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    email TEXT NOT NULL,
    code_hash TEXT NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    attempts INTEGER NOT NULL DEFAULT 0,
    consumed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE INDEX IF NOT EXISTS password_reset_codes_email_created_idx
    ON public.password_reset_codes (email, created_at DESC);

CREATE INDEX IF NOT EXISTS password_reset_codes_user_created_idx
    ON public.password_reset_codes (user_id, created_at DESC);

ALTER TABLE public.password_reset_codes ENABLE ROW LEVEL SECURITY;

-- No client-facing RLS policy is required; this table is service-role only via backend.

-- Rollback notes:
-- 1) DROP TABLE IF EXISTS public.password_reset_codes;
