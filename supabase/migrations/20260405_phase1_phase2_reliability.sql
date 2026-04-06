-- Phase 1 + Phase 2 reliability migration
-- Align chat/support persistence schema and add wallet + account deletion storage.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Chat room metadata fields expected by backend contract.
ALTER TABLE IF EXISTS public.chat_rooms
    ADD COLUMN IF NOT EXISTS topic TEXT,
    ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'closed')),
    ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES public.users(id) ON DELETE SET NULL;

-- Chat message compatibility aliases.
ALTER TABLE IF EXISTS public.chat_messages
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now());

-- Support ticket contract fields.
ALTER TABLE IF EXISTS public.support_tickets
    ADD COLUMN IF NOT EXISTS priority TEXT NOT NULL DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    ADD COLUMN IF NOT EXISTS assignee_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS resolution_note TEXT,
    ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    ADD COLUMN IF NOT EXISTS order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL;

-- Keep historical behavior safe if status or timestamps were nullable.
ALTER TABLE IF EXISTS public.support_tickets
    ALTER COLUMN status SET DEFAULT 'open';

UPDATE public.support_tickets
SET status = 'open'
WHERE status IS NULL;

-- Wallet support.
ALTER TABLE IF EXISTS public.users
    ADD COLUMN IF NOT EXISTS wallet_balance NUMERIC(10, 2) NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS public.wallet_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    amount NUMERIC(10, 2) NOT NULL,
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('topup', 'debit', 'credit', 'refund')),
    status TEXT NOT NULL DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'failed')),
    source TEXT,
    reference TEXT,
    idempotency_key TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE INDEX IF NOT EXISTS wallet_transactions_user_id_created_at_idx
    ON public.wallet_transactions (user_id, created_at DESC);

CREATE UNIQUE INDEX IF NOT EXISTS wallet_transactions_user_id_idempotency_idx
    ON public.wallet_transactions (user_id, idempotency_key)
    WHERE idempotency_key IS NOT NULL;

-- Account deletion workflow.
CREATE TABLE IF NOT EXISTS public.user_deletion_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
    status TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'cancelled', 'completed')),
    requested_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    delete_after TIMESTAMP WITH TIME ZONE NOT NULL,
    cancelled_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS user_deletion_requests_user_id_idx
    ON public.user_deletion_requests (user_id);

-- Helpful indexes for support/chat queries.
CREATE INDEX IF NOT EXISTS chat_room_participants_room_user_idx
    ON public.chat_room_participants (room_id, user_id);

CREATE INDEX IF NOT EXISTS chat_messages_room_sent_at_idx
    ON public.chat_messages (room_id, sent_at DESC);

CREATE INDEX IF NOT EXISTS support_tickets_user_id_updated_at_idx
    ON public.support_tickets (user_id, updated_at DESC);

CREATE TABLE IF NOT EXISTS public.support_ticket_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_id UUID REFERENCES public.support_tickets(id) ON DELETE CASCADE NOT NULL,
    actor_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    actor_role TEXT,
    event_type TEXT NOT NULL,
    event_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE INDEX IF NOT EXISTS support_ticket_events_ticket_created_idx
    ON public.support_ticket_events (ticket_id, created_at DESC);
