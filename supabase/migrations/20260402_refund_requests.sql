CREATE TABLE IF NOT EXISTS public.refund_requests (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  reason TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected')),
  admin_note TEXT,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  resolved_at TIMESTAMPTZ
);
ALTER TABLE public.refund_requests ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF NOT EXISTS (SELECT FROM pg_policies WHERE tablename = 'refund_requests' AND policyname = 'refund_owner_select') THEN
    CREATE POLICY "refund_owner_select" ON public.refund_requests FOR SELECT USING (auth.uid() = user_id);
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT FROM pg_policies WHERE tablename = 'refund_requests' AND policyname = 'refund_owner_insert') THEN
    CREATE POLICY "refund_owner_insert" ON public.refund_requests FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;
