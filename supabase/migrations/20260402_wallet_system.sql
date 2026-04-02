CREATE TABLE IF NOT EXISTS public.wallets (
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE PRIMARY KEY,
  balance DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  currency TEXT NOT NULL DEFAULT 'INR',
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.wallet_transactions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  wallet_user_id UUID REFERENCES public.wallets(user_id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('topup','debit','refund_credit')),
  amount DECIMAL(12,2) NOT NULL,
  reference TEXT,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallet_transactions ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF NOT EXISTS (SELECT FROM pg_policies WHERE tablename = 'wallets' AND policyname = 'wallet_owner_select') THEN
    CREATE POLICY "wallet_owner_select" ON public.wallets FOR SELECT USING (auth.uid() = user_id);
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT FROM pg_policies WHERE tablename = 'wallets' AND policyname = 'wallet_owner_update') THEN
    CREATE POLICY "wallet_owner_update" ON public.wallets FOR UPDATE USING (auth.uid() = user_id);
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT FROM pg_policies WHERE tablename = 'wallet_transactions' AND policyname = 'wallet_tx_owner_select') THEN
    CREATE POLICY "wallet_tx_owner_select" ON public.wallet_transactions FOR SELECT USING (auth.uid() = wallet_user_id);
  END IF;
END $$;
