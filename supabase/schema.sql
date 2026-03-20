-- Create required tables
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS users (
  id UUID REFERENCES auth.users NOT NULL PRIMARY KEY,
  role TEXT NOT NULL CHECK (role IN ('user', 'vendor', 'admin')) DEFAULT 'user',
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  campus_id TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS vendors (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  owner_id UUID REFERENCES public.users(id) NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  is_open BOOLEAN DEFAULT true,
  image_url TEXT,
  status TEXT NOT NULL CHECK (status IN ('pending', 'approved', 'rejected')) DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS campus_buildings (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  code TEXT,
  name TEXT NOT NULL,
  address TEXT,
  latitude DECIMAL(10,7),
  longitude DECIMAL(10,7),
  delivery_notes TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS delivery_zones (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  building_id UUID REFERENCES public.campus_buildings(id) ON DELETE SET NULL,
  geojson JSONB,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS class_sessions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  building_id UUID REFERENCES public.campus_buildings(id) ON DELETE SET NULL,
  room TEXT,
  course_label TEXT,
  starts_at TIMESTAMP WITH TIME ZONE,
  ends_at TIMESTAMP WITH TIME ZONE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS menus (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  vendor_id UUID REFERENCES public.vendors(id) ON DELETE CASCADE,
  category_name TEXT NOT NULL,
  sort_order INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS menu_items (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  menu_id UUID REFERENCES public.menus(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL,
  is_available BOOLEAN DEFAULT true,
  image_url TEXT
);

CREATE TABLE IF NOT EXISTS promotions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  code TEXT NOT NULL UNIQUE,
  description TEXT,
  discount_type TEXT NOT NULL CHECK (discount_type IN ('percent', 'fixed')),
  discount_value DECIMAL(10,2) NOT NULL,
  min_order_amount DECIMAL(10,2) DEFAULT 0,
  max_discount_amount DECIMAL(10,2),
  starts_at TIMESTAMP WITH TIME ZONE,
  ends_at TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN DEFAULT true,
  usage_limit INTEGER,
  usage_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS orders (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) NOT NULL,
  vendor_id UUID REFERENCES public.vendors(id) NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('pending', 'accepted', 'preparing', 'ready', 'completed', 'cancelled')) DEFAULT 'pending',
  delivery_mode TEXT NOT NULL CHECK (delivery_mode IN ('standard', 'class')) DEFAULT 'standard',
  delivery_instructions TEXT,
  delivery_location_label TEXT,
  delivery_building_id UUID REFERENCES public.campus_buildings(id) ON DELETE SET NULL,
  delivery_room TEXT,
  delivery_zone_id UUID REFERENCES public.delivery_zones(id) ON DELETE SET NULL,
  quiet_mode BOOLEAN DEFAULT false,
  handoff_code TEXT,
  handoff_status TEXT NOT NULL CHECK (handoff_status IN ('pending', 'arrived_building', 'arrived_class', 'delivered', 'failed')) DEFAULT 'pending',
  handoff_proof_url TEXT,
  class_start_at TIMESTAMP WITH TIME ZONE,
  class_end_at TIMESTAMP WITH TIME ZONE,
  scheduled_for TIMESTAMP WITH TIME ZONE,
  total_amount DECIMAL(10,2) NOT NULL,
  discount_amount DECIMAL(10,2) DEFAULT 0,
  promo_id UUID REFERENCES public.promotions(id),
  promo_code TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS order_delivery_locations (
  order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE PRIMARY KEY,
  lat DECIMAL(10,7) NOT NULL,
  lng DECIMAL(10,7) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS order_items (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
  item_id UUID REFERENCES public.menu_items(id),
  quantity INTEGER NOT NULL,
  unit_price DECIMAL(10,2) NOT NULL,
  special_instructions TEXT
);

CREATE TABLE IF NOT EXISTS payments (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('pending', 'successful', 'failed')) DEFAULT 'pending',
  provider_ref TEXT
);

CREATE TABLE IF NOT EXISTS promotion_redemptions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  promo_id UUID REFERENCES public.promotions(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
  redeemed_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS reviews (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
  vendor_id UUID REFERENCES public.vendors(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  rating INTEGER CHECK (rating >= 1 AND rating <= 5) NOT NULL,
  comment TEXT
);

CREATE TABLE IF NOT EXISTS notifications (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  audience TEXT NOT NULL CHECK (audience IN ('user', 'vendor', 'admin')) DEFAULT 'user',
  type TEXT DEFAULT 'general',
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  metadata JSONB,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS device_tokens (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  audience TEXT NOT NULL CHECK (audience IN ('user', 'vendor', 'admin')) DEFAULT 'user',
  token TEXT NOT NULL,
  platform TEXT NOT NULL CHECK (platform IN ('ios', 'android', 'web', 'unknown')) DEFAULT 'unknown',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(user_id, token)
);

CREATE TABLE IF NOT EXISTS favorites (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  vendor_id UUID REFERENCES public.vendors(id) ON DELETE CASCADE,
  UNIQUE(user_id, vendor_id)
);

CREATE TABLE IF NOT EXISTS user_carts (
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE PRIMARY KEY,
  items JSONB NOT NULL DEFAULT '[]'::jsonb,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS vendor_settings (
  vendor_id UUID REFERENCES public.vendors(id) ON DELETE CASCADE PRIMARY KEY,
  preparation_time_avg INTEGER DEFAULT 15,
  auto_accept_orders BOOLEAN DEFAULT false
);

CREATE TABLE IF NOT EXISTS admin_logs (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  admin_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  action_performed TEXT NOT NULL,
  target_id UUID,
  reason TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- RLS POLICIES
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menus ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_delivery_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promotions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promotion_redemptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_carts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendor_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campus_buildings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_zones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.class_sessions ENABLE ROW LEVEL SECURITY;

-- Drop policies if they exist so we can recreate them safely
DO $$ DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname, tablename FROM pg_policies WHERE schemaname = 'public') LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', r.policyname, r.tablename);
    END LOOP;
END $$;

-- Users can read their own data
CREATE POLICY "Users can view own profile" ON public.users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (auth.uid() = id);

-- Anyone can read active vendors
CREATE POLICY "Public can view vendors" ON public.vendors FOR SELECT USING (true);
CREATE POLICY "Vendors can update own data" ON public.vendors FOR UPDATE USING (auth.uid() = owner_id);

-- Anyone can read menus
CREATE POLICY "Public can view menus" ON public.menus FOR SELECT USING (true);
CREATE POLICY "Vendors can manage their menus" ON public.menus FOR ALL USING (
  EXISTS (SELECT 1 FROM public.vendors WHERE vendors.id = menus.vendor_id AND vendors.owner_id = auth.uid())
);

-- Anyone can read menu items
CREATE POLICY "Public can view menu items" ON public.menu_items FOR SELECT USING (true);
CREATE POLICY "Vendors can manage menu items" ON public.menu_items FOR ALL USING (
  EXISTS (
    SELECT 1 FROM public.menus 
    JOIN public.vendors ON vendors.id = menus.vendor_id
    WHERE menus.id = menu_items.menu_id AND vendors.owner_id = auth.uid()
  )
);

-- Order Security
CREATE POLICY "Users can view own orders" ON public.orders FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own orders" ON public.orders FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Vendors can view their orders" ON public.orders FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.vendors WHERE vendors.id = orders.vendor_id AND vendors.owner_id = auth.uid())
);
CREATE POLICY "Vendors can update their orders" ON public.orders FOR UPDATE USING (
  EXISTS (SELECT 1 FROM public.vendors WHERE vendors.id = orders.vendor_id AND vendors.owner_id = auth.uid())
);

CREATE POLICY "Users can insert own order items" ON public.order_items FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.orders
    WHERE orders.id = order_items.order_id
      AND orders.user_id = auth.uid()
  )
);

CREATE POLICY "Users and vendors can view order items" ON public.order_items FOR SELECT USING (
  EXISTS (
    SELECT 1
    FROM public.orders
    WHERE orders.id = order_items.order_id
      AND (
        orders.user_id = auth.uid()
        OR EXISTS (
          SELECT 1
          FROM public.vendors
          WHERE vendors.id = orders.vendor_id AND vendors.owner_id = auth.uid()
        )
      )
  )
);

CREATE POLICY "Vendors can upsert delivery locations" ON public.order_delivery_locations FOR ALL USING (
  EXISTS (
    SELECT 1 FROM public.orders
    JOIN public.vendors ON vendors.id = orders.vendor_id
    WHERE orders.id = order_delivery_locations.order_id AND vendors.owner_id = auth.uid()
  )
);

CREATE POLICY "Users can view delivery locations" ON public.order_delivery_locations FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.orders
    WHERE orders.id = order_delivery_locations.order_id AND orders.user_id = auth.uid()
  )
);

-- Campus buildings and zones
CREATE POLICY "Public can view campus buildings" ON public.campus_buildings FOR SELECT USING (true);
CREATE POLICY "Public can view delivery zones" ON public.delivery_zones FOR SELECT USING (true);

-- Class sessions (user schedule)
CREATE POLICY "Users can manage own class sessions" ON public.class_sessions FOR ALL USING (auth.uid() = user_id);

-- User carts
CREATE POLICY "Users can view own cart" ON public.user_carts FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own cart" ON public.user_carts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own cart" ON public.user_carts FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own cart" ON public.user_carts FOR DELETE USING (auth.uid() = user_id);

-- Promotions
CREATE POLICY "Public can view active promotions" ON public.promotions FOR SELECT USING (
  is_active = true AND (starts_at IS NULL OR starts_at <= now()) AND (ends_at IS NULL OR ends_at >= now())
);

-- Notifications
CREATE POLICY "Users can view own notifications" ON public.notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own notifications" ON public.notifications FOR UPDATE USING (auth.uid() = user_id);

-- Device tokens
CREATE POLICY "Users can manage own device tokens" ON public.device_tokens FOR ALL USING (auth.uid() = user_id);

-- Promotion redemptions
CREATE POLICY "Users can view own promo redemptions" ON public.promotion_redemptions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own promo redemptions" ON public.promotion_redemptions FOR INSERT WITH CHECK (auth.uid() = user_id);
