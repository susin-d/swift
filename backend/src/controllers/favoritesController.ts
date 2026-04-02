import { FastifyRequest, FastifyReply } from 'fastify';
import { supabase } from '../services/supabase';

// Ensure favorites table exists as a simple join table; uses public.favorites (user_id, vendor_id)
// Returns current vendor_ids for the user

export const getFavorites = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const { data, error } = await supabase
        .from('favorites')
        .select('vendor_id')
        .eq('user_id', user.sub);
    if (error) throw error;
    return reply.send({ vendor_ids: (data ?? []).map((r: any) => r.vendor_id) });
};

export const addFavorite = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const { vendorId } = request.params as { vendorId: string };
    await supabase
        .from('favorites')
        .upsert({ user_id: user.sub, vendor_id: vendorId }, { onConflict: 'user_id,vendor_id', ignoreDuplicates: true });
    const { data, error } = await supabase
        .from('favorites')
        .select('vendor_id')
        .eq('user_id', user.sub);
    if (error) throw error;
    return reply.send({ vendor_ids: (data ?? []).map((r: any) => r.vendor_id) });
};

export const removeFavorite = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const { vendorId } = request.params as { vendorId: string };
    await supabase
        .from('favorites')
        .delete()
        .eq('user_id', user.sub)
        .eq('vendor_id', vendorId);
    const { data, error } = await supabase
        .from('favorites')
        .select('vendor_id')
        .eq('user_id', user.sub);
    if (error) throw error;
    return reply.send({ vendor_ids: (data ?? []).map((r: any) => r.vendor_id) });
};
