-- Add vendor store-control fields for busy mode and holiday scheduling.
ALTER TABLE public.vendor_settings
    ADD COLUMN IF NOT EXISTS busy_mode_enabled BOOLEAN DEFAULT false,
    ADD COLUMN IF NOT EXISTS busy_mode_message TEXT,
    ADD COLUMN IF NOT EXISTS holiday_until TIMESTAMP WITH TIME ZONE;

-- Rollback notes:
-- 1) ALTER TABLE public.vendor_settings DROP COLUMN IF EXISTS holiday_until;
-- 2) ALTER TABLE public.vendor_settings DROP COLUMN IF EXISTS busy_mode_message;
-- 3) ALTER TABLE public.vendor_settings DROP COLUMN IF EXISTS busy_mode_enabled;
