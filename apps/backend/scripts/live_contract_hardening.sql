-- Live Contract Hardening Migration
-- Purpose:
-- 1) Align production schema with v1 backend expectations for orders/admin audit/reviews.
-- 2) Ensure authenticated role can insert order_items and promotion_redemptions when RLS is enabled.
-- 3) Backfill missing columns safely without destructive changes.

BEGIN;

-- Ensure required order columns exist for delivery-to-class and promo flows.
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

-- Default/backfill to avoid null constraint failures for new runtime assumptions.
UPDATE public.orders
SET delivery_mode = COALESCE(delivery_mode, 'standard')
WHERE delivery_mode IS NULL;

UPDATE public.orders
SET handoff_status = COALESCE(handoff_status, 'pending')
WHERE handoff_status IS NULL;

-- Add constraints only when absent.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'orders_delivery_mode_check'
      AND conrelid = 'public.orders'::regclass
  ) THEN
    ALTER TABLE public.orders
      ADD CONSTRAINT orders_delivery_mode_check
      CHECK (delivery_mode IN ('standard', 'class'));
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'orders_handoff_status_check'
      AND conrelid = 'public.orders'::regclass
  ) THEN
    ALTER TABLE public.orders
      ADD CONSTRAINT orders_handoff_status_check
      CHECK (handoff_status IN ('pending', 'arrived_building', 'arrived_class', 'delivered', 'failed'));
  END IF;
END $$;

-- Ensure audit reason exists for compliance logging.
ALTER TABLE public.admin_logs ADD COLUMN IF NOT EXISTS reason TEXT;

-- Ensure reviews table exists with expected shape.
CREATE TABLE IF NOT EXISTS public.reviews (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
  vendor_id UUID REFERENCES public.vendors(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  rating INTEGER CHECK (rating >= 1 AND rating <= 5) NOT NULL,
  comment TEXT
);

-- If older schemas use menu_item_id or price instead of item_id/unit_price, add compatibility columns.
ALTER TABLE public.order_items ADD COLUMN IF NOT EXISTS menu_item_id UUID REFERENCES public.menu_items(id);
ALTER TABLE public.order_items ADD COLUMN IF NOT EXISTS price DECIMAL(10,2);

UPDATE public.order_items
SET menu_item_id = COALESCE(menu_item_id, item_id)
WHERE menu_item_id IS NULL;

UPDATE public.order_items
SET price = COALESCE(price, unit_price)
WHERE price IS NULL;

-- RLS and policies for order_items/promotion_redemptions in auth-token execution mode.
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promotion_redemptions ENABLE ROW LEVEL SECURITY;

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

DROP POLICY IF EXISTS "Users can view own order items" ON public.order_items;
CREATE POLICY "Users can view own order items"
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

DROP POLICY IF EXISTS "Users can insert own promo redemptions" ON public.promotion_redemptions;
CREATE POLICY "Users can insert own promo redemptions"
ON public.promotion_redemptions
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Keep explicit grants in case deployment reset privileges.
GRANT SELECT, INSERT, UPDATE, DELETE ON public.orders TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.order_items TO authenticated;
GRANT SELECT, INSERT ON public.promotion_redemptions TO authenticated;
GRANT SELECT ON public.reviews TO anon, authenticated;
GRANT SELECT ON public.admin_logs TO authenticated;

COMMIT;
