-- Migration: Delivery Location Tracking

-- 1. Create order_delivery_locations table
CREATE TABLE IF NOT EXISTS public.order_delivery_locations (
    order_id UUID PRIMARY KEY REFERENCES public.orders(id) ON DELETE CASCADE,
    lat DECIMAL(10, 8) NOT NULL,
    lng DECIMAL(11, 8) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Enable RLS
ALTER TABLE public.order_delivery_locations ENABLE ROW LEVEL SECURITY;

-- 3. RLS Policies

-- Anyone authenticated can view (simplified for now, ideally restrict to order owner/vendor/admin)
CREATE POLICY "Users can view order location" ON public.order_delivery_locations FOR SELECT TO authenticated USING (
    EXISTS (
        SELECT 1 FROM public.orders 
        WHERE orders.id = order_delivery_locations.order_id 
        AND (orders.user_id = auth.uid() OR orders.vendor_id IN (SELECT id FROM public.vendors WHERE owner_id = auth.uid()) OR EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'))
    )
);

-- Vendors and Admins can update/insert location
CREATE POLICY "Vendors and Admins can upsert location" ON public.order_delivery_locations FOR ALL TO authenticated USING (
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE users.id = auth.uid() 
        AND (users.role = 'vendor' OR users.role = 'admin')
    )
);

-- 4. Trigger for updated_at
CREATE OR REPLACE FUNCTION update_delivery_location_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_order_delivery_locations_timestamp
    BEFORE UPDATE ON public.order_delivery_locations
    FOR EACH ROW
    EXECUTE PROCEDURE update_delivery_location_timestamp();
