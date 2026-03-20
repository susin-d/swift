import { FastifyReply, FastifyRequest } from 'fastify';
import { supabase } from '../services/supabase';
import { normalizePromoCode, validatePromo } from '../services/promoService';

export const getActivePromos = async (_request: FastifyRequest, reply: FastifyReply) => {
    const nowIso = new Date().toISOString();
    const { data, error } = await supabase
        .from('promotions')
        .select('*')
        .eq('is_active', true)
        .or(`starts_at.is.null,starts_at.lte.${nowIso}`)
        .or(`ends_at.is.null,ends_at.gte.${nowIso}`)
        .order('created_at', { ascending: false });

    if (error) throw error;
    return reply.send(data || []);
};

export const validatePromoCode = async (request: FastifyRequest, reply: FastifyReply) => {
    const { code, order_total, order_amount } = request.body as any;
    const total = Number(order_total || order_amount || 0);
    if (!code || total <= 0) {
        const err = new Error('Promo code and order_total are required') as any;
        err.statusCode = 400;
        throw err;
    }

    const result = await validatePromo(code, total);
    return reply.send({
        promo_id: result.promo.id,
        code: result.promo.code,
        description: result.promo.description,
        discount_type: result.promo.discount_type,
        discount_value: result.promo.discount_value,
        discount_amount: result.discount_amount,
        final_amount: result.final_amount,
    });
};

export const getAdminPromos = async (_request: FastifyRequest, reply: FastifyReply) => {
    const { data, error } = await supabase
        .from('promotions')
        .select('*')
        .order('created_at', { ascending: false });

    if (error) throw error;
    return reply.send(data || []);
};

export const createPromo = async (request: FastifyRequest, reply: FastifyReply) => {
    const payload = request.body as any;

    const code = normalizePromoCode(payload.code || '');
    if (!code) {
        const err = new Error('Promo code is required') as any;
        err.statusCode = 400;
        throw err;
    }

    const record = {
        code,
        description: payload.description || null,
        discount_type: payload.discount_type || 'percent',
        discount_value: Number(payload.discount_value || 0),
        min_order_amount: Number(payload.min_order_amount || 0),
        max_discount_amount: payload.max_discount_amount !== undefined ? Number(payload.max_discount_amount) : null,
        starts_at: payload.starts_at || null,
        ends_at: payload.ends_at || null,
        is_active: payload.is_active ?? true,
        usage_limit: payload.usage_limit !== undefined ? Number(payload.usage_limit) : null,
    };

    const { data, error } = await supabase
        .from('promotions')
        .insert(record)
        .select()
        .single();

    if (error) throw error;
    return reply.code(201).send(data);
};

export const updatePromo = async (request: FastifyRequest, reply: FastifyReply) => {
    const { id } = request.params as any;
    const payload = request.body as any;

    const updates: Record<string, any> = {};
    if (payload.description !== undefined) updates.description = payload.description;
    if (payload.discount_type !== undefined) updates.discount_type = payload.discount_type;
    if (payload.discount_value !== undefined) updates.discount_value = Number(payload.discount_value);
    if (payload.min_order_amount !== undefined) updates.min_order_amount = Number(payload.min_order_amount);
    if (payload.max_discount_amount !== undefined) updates.max_discount_amount = payload.max_discount_amount === null ? null : Number(payload.max_discount_amount);
    if (payload.starts_at !== undefined) updates.starts_at = payload.starts_at;
    if (payload.ends_at !== undefined) updates.ends_at = payload.ends_at;
    if (payload.is_active !== undefined) updates.is_active = payload.is_active;
    if (payload.usage_limit !== undefined) updates.usage_limit = payload.usage_limit === null ? null : Number(payload.usage_limit);

    const { data, error } = await supabase
        .from('promotions')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    if (error) throw error;
    return reply.send(data);
};
