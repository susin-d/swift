-- This script can be run using pgTAP (https://pgtap.org) in the Supabase test environment
BEGIN;
SELECT plan(4);

-- 1. Test Users RLS
SET role authenticated;
SET request.jwt.claim.sub = 'bbbbbbbb-1111-2222-3333-444444444444';

-- Attempting to read all users should only return the mocked user's row
SELECT matches(
    $$ SELECT count(*) FROM public.users $$,
    $$ ^[01]$ $$,
    'RLS: users can only see their own profile mapping'
);

-- 2. Test Vendor Menu Management RLS
SET request.jwt.claim.sub = 'vendor-9999-owner-id';
-- Testing insert refusal
SELECT throws_ok(
    $$ INSERT INTO public.menus (vendor_id, category_name) VALUES ('not-my-vendor-id', 'Illegal Meals') $$,
    'new row violates row-level security policy for table "menus"',
    'RLS: vendors cannot insert menus for other vendors'
);

-- 3. Test Order reading scope
SELECT is(
    (SELECT count(*) FROM public.orders WHERE user_id != 'bbbbbbbb-1111-2222-3333-444444444444'),
    0::bigint,
    'RLS: Assured that authenticated user token cannot select other users orders'
);

SELECT finish();
ROLLBACK;
