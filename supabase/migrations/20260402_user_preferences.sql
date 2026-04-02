CREATE TABLE IF NOT EXISTS public.user_preferences (
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE PRIMARY KEY,
  allergies TEXT[] NOT NULL DEFAULT '{}',
  dietary_tags TEXT[] NOT NULL DEFAULT '{}',
  cuisine_blacklist TEXT[] NOT NULL DEFAULT '{}',
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF NOT EXISTS (SELECT FROM pg_policies WHERE tablename = 'user_preferences' AND policyname = 'pref_owner') THEN
    CREATE POLICY "pref_owner" ON public.user_preferences FOR ALL USING (auth.uid() = user_id);
  END IF;
END $$;
