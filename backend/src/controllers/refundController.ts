import { FastifyRequest, FastifyReply } from 'fastify';
import { supabase } from '../services/supabase';

export const requestRefund = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const { id: orderId } = request.params as { id: string };
    const { reason } = request.body as { reason: string };
    if (!reason || reason.trim().length < 10) {
        return reply.code(400).send({ error: 'InvalidReason', message: 'Reason must be at least 10 characters' });
    }
    // Validate order belongs to user and is completed/cancelled
    const { data: order, error: orderError } = await supabase
        .from('orders')
        .select('id, status, user_id')
        .eq('id', orderId)
        .eq('user_id', user.sub)
        .single();
    if (orderError || !order) {
        return reply.code(404).send({ error: 'NotFound', message: 'Order not found' });
    }
    if (!['completed', 'cancelled'].includes((order as any).status)) {
        return reply.code(400).send({ error: 'InvalidStatus', message: 'Refunds can only be requested for completed or cancelled orders' });
    }
    // Check no pending refund exists
    const { data: existing } = await supabase
        .from('refund_requests')
        .select('id')
        .eq('order_id', orderId)
        .eq('user_id', user.sub)
        .eq('status', 'pending')
        .maybeSingle();
    if (existing) {
        return reply.code(409).send({ error: 'Conflict', message: 'A pending refund request already exists for this order' });
    }
    const { data: refund, error } = await supabase
        .from('refund_requests')
        .insert({ order_id: orderId, user_id: user.sub, reason: reason.trim() })
        .select('*')
        .single();
    if (error) throw error;
    return reply.code(201).send({ refund_request: refund });
};

export const getMyRefunds = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const query = request.query as { page?: string; per_page?: string };
    const page = Math.max(1, parseInt(query.page ?? '1', 10));
    const perPage = Math.min(100, Math.max(1, parseInt(query.per_page ?? '20', 10)));
    const from = (page - 1) * perPage;
    const to = from + perPage - 1;
    const { data, error, count } = await supabase
        .from('refund_requests')
        .select('*, orders(id, total_amount, vendor_id, created_at, vendors(name))', { count: 'exact' })
        .eq('user_id', user.sub)
        .order('created_at', { ascending: false })
        .range(from, to);
    if (error) throw error;
    return reply.send({ refunds: data ?? [], meta: { total: count ?? 0, page, per_page: perPage } });
};

export const getAdminRefunds = async (request: FastifyRequest, reply: FastifyReply) => {
    const query = request.query as { page?: string; per_page?: string; status?: string };
    const page = Math.max(1, parseInt(query.page ?? '1', 10));
    const perPage = Math.min(100, Math.max(1, parseInt(query.per_page ?? '20', 10)));
    const from = (page - 1) * perPage;
    const to = from + perPage - 1;
    let q = supabase
        .from('refund_requests')
        .select('*, orders(id, total_amount, vendor_id, created_at, vendors(name)), users(id, email, name)', { count: 'exact' })
        .order('created_at', { ascending: false })
        .range(from, to);
    if (query.status) q = (q as any).eq('status', query.status);
    const { data, error, count } = await q;
    if (error) throw error;
    return reply.send({ refunds: data ?? [], meta: { total: count ?? 0, page, per_page: perPage } });
};

export const resolveRefund = async (request: FastifyRequest, reply: FastifyReply) => {
    const { id } = request.params as { id: string };
    const { status, admin_note } = request.body as { status: 'approved' | 'rejected'; admin_note: string };
    if (!['approved', 'rejected'].includes(status)) {
        return reply.code(400).send({ error: 'InvalidStatus', message: 'Status must be approved or rejected' });
    }
    if (!admin_note || admin_note.trim().length === 0) {
        return reply.code(400).send({ error: 'MissingNote', message: 'admin_note is required' });
    }
    const { data, error } = await supabase
        .from('refund_requests')
        .update({ status, admin_note: admin_note.trim(), resolved_at: new Date().toISOString() })
        .eq('id', id)
        .select('*')
        .single();
    if (error) throw error;
    return reply.send(data);
};
