import { FastifyRequest, FastifyReply } from 'fastify';
import { supabase } from '../services/supabase';

export const listAdminPromos = async (request: FastifyRequest, reply: FastifyReply) => {
    const query = request.query as { page?: string; per_page?: string };
    const page = Math.max(1, parseInt(query.page ?? '1', 10));
    const perPage = Math.min(100, Math.max(1, parseInt(query.per_page ?? '20', 10)));
    const from = (page - 1) * perPage;
    const to = from + perPage - 1;
    const { data, error, count } = await supabase
        .from('promotions')
        .select('*', { count: 'exact' })
        .order('created_at', { ascending: false })
        .range(from, to);
    if (error) throw error;
    const totalPages = Math.ceil((count ?? 0) / perPage);
    return reply.send({ promos: data ?? [], meta: { total: count ?? 0, page, per_page: perPage, total_pages: totalPages } });
};

export const createAdminPromo = async (request: FastifyRequest, reply: FastifyReply) => {
    const body = request.body as {
        code: string;
        description?: string;
        discount_type: string;
        discount_value: number;
        min_order_amount?: number;
        max_discount_amount?: number;
        starts_at?: string;
        ends_at?: string;
        usage_limit?: number;
    };
    if (!body.code || !body.code.trim()) {
        return reply.code(400).send({ error: 'MissingCode', message: 'Promo code is required' });
    }
    if (!['percent', 'fixed'].includes(body.discount_type)) {
        return reply.code(400).send({ error: 'InvalidDiscountType', message: 'discount_type must be percent or fixed' });
    }
    if (!body.discount_value || Number(body.discount_value) <= 0) {
        return reply.code(400).send({ error: 'InvalidValue', message: 'discount_value must be greater than 0' });
    }
    const { data, error } = await supabase
        .from('promotions')
        .insert({
            code: body.code.trim().toUpperCase(),
            description: body.description ?? null,
            discount_type: body.discount_type,
            discount_value: Number(body.discount_value),
            min_order_amount: Number(body.min_order_amount ?? 0),
            max_discount_amount: body.max_discount_amount ? Number(body.max_discount_amount) : null,
            starts_at: body.starts_at ?? null,
            ends_at: body.ends_at ?? null,
            usage_limit: body.usage_limit ? Number(body.usage_limit) : null,
            is_active: true,
        })
        .select('*')
        .single();
    if (error) {
        if (error.code === '23505') {
            return reply.code(409).send({ error: 'Conflict', message: 'Promo code already exists' });
        }
        throw error;
    }
    return reply.code(201).send(data);
};

export const updateAdminPromo = async (request: FastifyRequest, reply: FastifyReply) => {
    const { id } = request.params as { id: string };
    const body = request.body as Record<string, any>;
    const allowed = [
        'code', 'description', 'discount_type', 'discount_value',
        'min_order_amount', 'max_discount_amount', 'starts_at', 'ends_at',
        'usage_limit', 'is_active',
    ];
    const updates: Record<string, any> = {};
    for (const key of allowed) {
        if (key in body) updates[key] = body[key];
    }
    if (Object.keys(updates).length === 0) {
        return reply.code(400).send({ error: 'NoUpdates', message: 'No valid fields provided' });
    }
    const { data, error } = await supabase
        .from('promotions')
        .update(updates)
        .eq('id', id)
        .select('*')
        .single();
    if (error) throw error;
    return reply.send(data);
};

export const deleteAdminPromo = async (request: FastifyRequest, reply: FastifyReply) => {
    const { id } = request.params as { id: string };
    const { error } = await supabase
        .from('promotions')
        .update({ is_active: false })
        .eq('id', id);
    if (error) throw error;
    return reply.send({ message: 'Promo deactivated' });
};
