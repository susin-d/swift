-- FINAL LAUNCH DB FIX
-- Run this once in Supabase SQL Editor (safe to re-run; idempotent where possible).
-- Goal: eliminate remaining order creation access failures and align live DB with API contract.

BEGIN;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- 1) SCHEMA ALIGNMENT (orders / order_items / admin_logs / reviews)
-- ============================================================================

-- Orders: delivery-to-class + promo + handoff columns expected by backend
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_mode TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_instructions TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_location_label TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_building_id UUID REFERENCES public.campus_buildings(id) ON DELETE SET NULL;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_room TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_zone_id UUID REFERENCES public.delivery_zones(id) ON DELETE SET NULL;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS quiet_mode BOOLEAN DEFAULT false;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS handoff_code TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS handoff_status TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS handoff_proof_url TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS class_start_at TIMESTAMPTZ;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS class_end_at TIMESTAMPTZ;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS discount_amount DECIMAL(10,2) DEFAULT 0;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS promo_id UUID REFERENCES public.promotions(id);
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS promo_code TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS scheduled_for TIMESTAMPTZ;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL;

UPDATE public.orders
SET delivery_mode = COALESCE(delivery_mode, 'standard')
WHERE delivery_mode IS NULL;

UPDATE public.orders
SET handoff_status = COALESCE(handoff_status, 'pending')
WHERE handoff_status IS NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'orders_delivery_mode_check'
      AND conrelid = 'public.orders'::regclass
  ) THEN
    ALTER TABLE public.orders
      ADD CONSTRAINT orders_delivery_mode_check
      CHECK (delivery_mode IN ('standard', 'class'));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'orders_handoff_status_check'
      AND conrelid = 'public.orders'::regclass
  ) THEN
    ALTER TABLE public.orders
      ADD CONSTRAINT orders_handoff_status_check
      CHECK (handoff_status IN ('pending', 'arrived_building', 'arrived_class', 'delivered', 'failed'));
  END IF;
END $$;

-- order_items compatibility columns for mixed deployments
ALTER TABLE public.order_items ADD COLUMN IF NOT EXISTS menu_item_id UUID REFERENCES public.menu_items(id);
ALTER TABLE public.order_items ADD COLUMN IF NOT EXISTS price DECIMAL(10,2);

UPDATE public.order_items
SET menu_item_id = COALESCE(menu_item_id, item_id)
WHERE menu_item_id IS NULL;

UPDATE public.order_items
SET price = COALESCE(price, unit_price)
WHERE price IS NULL;

-- Compliance support for audit reasons
ALTER TABLE public.admin_logs ADD COLUMN IF NOT EXISTS reason TEXT;

-- Reviews table safety (if missing in environment)
CREATE TABLE IF NOT EXISTS public.reviews (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
  vendor_id UUID REFERENCES public.vendors(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  rating INTEGER CHECK (rating >= 1 AND rating <= 5) NOT NULL,
  comment TEXT
);

-- ============================================================================
-- 2) RLS / POLICY HARDENING
-- ============================================================================

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promotion_redemptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_logs ENABLE ROW LEVEL SECURITY;

-- orders policies
DROP POLICY IF EXISTS "Users can insert own orders" ON public.orders;
CREATE POLICY "Users can insert own orders"
ON public.orders
FOR INSERT
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
CREATE POLICY "Users can view own orders"
ON public.orders
FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Vendors can view their orders" ON public.orders;
CREATE POLICY "Vendors can view their orders"
ON public.orders
FOR SELECT
USING (
  EXISTS (
    SELECT 1
    FROM public.vendors
    WHERE vendors.id = orders.vendor_id
      AND vendors.owner_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Vendors can update their orders" ON public.orders;
CREATE POLICY "Vendors can update their orders"
ON public.orders
FOR UPDATE
USING (
  EXISTS (
    SELECT 1
    FROM public.vendors
    WHERE vendors.id = orders.vendor_id
      AND vendors.owner_id = auth.uid()
  )
);

-- order_items policies
DROP POLICY IF EXISTS "Users can insert own order items" ON public.order_items;
CREATE POLICY "Users can insert own order items"
ON public.order_items
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.orders
    WHERE orders.id = order_items.order_id
      AND orders.user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Users and vendors can view order items" ON public.order_items;
CREATE POLICY "Users and vendors can view order items"
ON public.order_items
FOR SELECT
USING (
  EXISTS (
    SELECT 1
    FROM public.orders
    WHERE orders.id = order_items.order_id
      AND (
        orders.user_id = auth.uid()
        OR EXISTS (
          SELECT 1
          FROM public.vendors
          WHERE vendors.id = orders.vendor_id
            AND vendors.owner_id = auth.uid()
        )
      )
  )
);

-- promotion_redemptions policies
DROP POLICY IF EXISTS "Users can view own promo redemptions" ON public.promotion_redemptions;
CREATE POLICY "Users can view own promo redemptions"
ON public.promotion_redemptions
FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own promo redemptions" ON public.promotion_redemptions;
CREATE POLICY "Users can insert own promo redemptions"
ON public.promotion_redemptions
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- reviews policies (public reads + owner create)
DROP POLICY IF EXISTS "Public can view reviews" ON public.reviews;
CREATE POLICY "Public can view reviews"
ON public.reviews
FOR SELECT
USING (true);

DROP POLICY IF EXISTS "Users can create own reviews" ON public.reviews;
CREATE POLICY "Users can create own reviews"
ON public.reviews
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- admin_logs read policy for authenticated admins through app role checks
DROP POLICY IF EXISTS "Authenticated can read admin logs" ON public.admin_logs;
CREATE POLICY "Authenticated can read admin logs"
ON public.admin_logs
FOR SELECT
USING (auth.uid() IS NOT NULL);

-- ============================================================================
-- 3) GRANTS (defensive)
-- ============================================================================

GRANT USAGE ON SCHEMA public TO anon, authenticated;

-- Reset overly-broad grants that can obscure policy debugging and weaken security.
REVOKE ALL PRIVILEGES ON public.orders FROM anon, authenticated;
REVOKE ALL PRIVILEGES ON public.order_items FROM anon, authenticated;
REVOKE ALL PRIVILEGES ON public.promotion_redemptions FROM anon, authenticated;
REVOKE ALL PRIVILEGES ON public.reviews FROM anon, authenticated;
REVOKE ALL PRIVILEGES ON public.admin_logs FROM anon, authenticated;

GRANT SELECT ON public.reviews TO anon, authenticated;
GRANT SELECT ON public.orders TO authenticated;
GRANT INSERT, UPDATE ON public.orders TO authenticated;
GRANT SELECT ON public.order_items TO authenticated;
GRANT INSERT ON public.order_items TO authenticated;
GRANT SELECT, INSERT ON public.promotion_redemptions TO authenticated;
GRANT SELECT ON public.admin_logs TO authenticated;

COMMIT;

-- ============================================================================
-- 4) VERIFICATION QUERIES (run after commit)
-- ============================================================================

-- Required columns
SELECT table_name, column_name
FROM information_schema.columns
WHERE table_schema = 'public'
  AND (
    (table_name = 'orders' AND column_name IN (
      'delivery_mode','delivery_building_id','delivery_zone_id','handoff_status','discount_amount','promo_id','promo_code'
    ))
    OR (table_name = 'order_items' AND column_name IN ('item_id','menu_item_id','unit_price','price'))
    OR (table_name = 'admin_logs' AND column_name IN ('reason'))
  )
ORDER BY table_name, column_name;

-- RLS state
SELECT schemaname, tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('orders','order_items','promotion_redemptions','reviews','admin_logs')
ORDER BY tablename;

-- Policies
SELECT tablename, policyname, cmd
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('orders','order_items','promotion_redemptions','reviews','admin_logs')
ORDER BY tablename, policyname;

-- Grants
SELECT table_name, grantee, privilege_type
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
  AND table_name IN ('orders','order_items','promotion_redemptions','reviews','admin_logs')
  AND grantee IN ('anon','authenticated')
ORDER BY table_name, grantee, privilege_type;
