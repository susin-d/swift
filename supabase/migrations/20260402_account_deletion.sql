CREATE TABLE IF NOT EXISTS public.deletion_requests (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  requested_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  confirmed_at TIMESTAMPTZ,
  executed_at TIMESTAMPTZ,
  token TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL
);
ALTER TABLE public.deletion_requests ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF NOT EXISTS (SELECT FROM pg_policies WHERE tablename = 'deletion_requests' AND policyname = 'deletion_req_owner') THEN
    CREATE POLICY "deletion_req_owner" ON public.deletion_requests FOR ALL USING (auth.uid() = user_id);
  END IF;
END $$;
