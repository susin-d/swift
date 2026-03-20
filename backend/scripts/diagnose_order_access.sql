-- Diagnose order creation access issues in production
-- Run this in Supabase SQL editor and inspect outputs.

-- 1) Verify required order columns exist
SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'orders'
  AND column_name IN (
    'delivery_mode',
    'delivery_building_id',
    'delivery_zone_id',
    'handoff_status',
    'discount_amount',
    'promo_id',
    'promo_code'
  )
ORDER BY column_name;

-- 2) Check table-level RLS state
SELECT schemaname, tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('orders', 'order_items', 'promotion_redemptions', 'admin_logs', 'reviews');

-- 3) Show policies that affect order writes
SELECT schemaname, tablename, policyname, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('orders', 'order_items', 'promotion_redemptions')
ORDER BY tablename, policyname;

-- 4) Verify grants for authenticated role
SELECT table_schema, table_name, privilege_type, grantee
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
  AND table_name IN ('orders', 'order_items', 'promotion_redemptions', 'reviews', 'admin_logs')
  AND grantee IN ('authenticated', 'anon')
ORDER BY table_name, grantee, privilege_type;

-- 5) Verify vendor status for the failing vendor id
SELECT id, owner_id, name, status, is_open
FROM public.vendors
WHERE id = '17209676-e918-46e9-a307-a70cb8f9e4cf';
