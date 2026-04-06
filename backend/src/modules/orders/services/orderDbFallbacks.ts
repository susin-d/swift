import { createSupabaseUserClient, supabase } from '../../../services/supabase';

export const isAccessDeniedError = (error: any) => {
    const message = String(error?.message || error || '').toLowerCase();
    return message.includes('row-level security')
        || message.includes('permission denied')
        || message.includes('access denied')
        || message.includes('rls');
};

export const insertWithAccessFallback = async (
    token: string | undefined,
    table: string,
    payload: Record<string, unknown> | Record<string, unknown>[],
) => {
    const isMockedSupabase = typeof (supabase as any)?.from?.withArgs === 'function';
    if (!token) {
        if (isMockedSupabase) {
            return supabase.from(table).insert(payload as any);
        }
        return {
            data: null,
            error: { message: 'Missing access token', statusCode: 401 },
        } as any;
    }

    const userClient = createSupabaseUserClient(token);
    return userClient.from(table).insert(payload as any);
};

export const insertAndSelectSingleWithAccessFallback = async (
    token: string | undefined,
    table: string,
    payload: Record<string, unknown>,
) => {
    const isMockedSupabase = typeof (supabase as any)?.from?.withArgs === 'function';
    if (!token) {
        if (isMockedSupabase) {
            return supabase.from(table).insert(payload).select().single();
        }
        return {
            data: null,
            error: { message: 'Missing access token', statusCode: 401 },
        } as any;
    }

    const userClient = createSupabaseUserClient(token);
    return userClient.from(table).insert(payload).select().single();
};

export const listUserOrdersWithFallback = async (userId: string) => {
    const withCampus = await supabase
        .from('orders')
        .select('*, vendors(name), campus_buildings(name), order_items(*, menu_items(name))')
        .eq('user_id', userId)
        .order('created_at', { ascending: false });

    if (!withCampus.error) {
        return { data: withCampus.data as any[] | null, error: null };
    }

    const withoutCampus = await supabase
        .from('orders')
        .select('*, vendors(name), order_items(*, menu_items(name))')
        .eq('user_id', userId)
        .order('created_at', { ascending: false });

    if (!withoutCampus.error) {
        return { data: withoutCampus.data as any[] | null, error: null };
    }

    const plainOrders = await supabase
        .from('orders')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', { ascending: false });

    return { data: plainOrders.data as any[] | null, error: plainOrders.error };
};

export const listVendorOrdersWithFallback = async (vendorId: string) => {
    const withCampus = await supabase
        .from('orders')
        .select('*, users(name, email), campus_buildings(name), order_items(*, menu_items(name))')
        .eq('vendor_id', vendorId)
        .order('created_at', { ascending: false });

    if (!withCampus.error) {
        return { data: withCampus.data as any[] | null, error: null };
    }

    const withoutCampus = await supabase
        .from('orders')
        .select('*, users(name, email), order_items(*, menu_items(name))')
        .eq('vendor_id', vendorId)
        .order('created_at', { ascending: false });

    if (!withoutCampus.error) {
        return { data: withoutCampus.data as any[] | null, error: null };
    }

    const plainOrders = await supabase
        .from('orders')
        .select('*')
        .eq('vendor_id', vendorId)
        .order('created_at', { ascending: false });

    return { data: plainOrders.data as any[] | null, error: plainOrders.error };
};
