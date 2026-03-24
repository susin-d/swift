-- Add audit timestamps to menu categories and menu items.
ALTER TABLE public.menus
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL;

ALTER TABLE public.menu_items
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL;

-- Rollback notes:
-- 1) ALTER TABLE public.menu_items
--      DROP COLUMN IF EXISTS updated_at,
--      DROP COLUMN IF EXISTS created_at;
-- 2) ALTER TABLE public.menus
--      DROP COLUMN IF EXISTS updated_at,
--      DROP COLUMN IF EXISTS created_at;
