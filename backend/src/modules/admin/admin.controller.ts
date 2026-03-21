import { FastifyRequest, FastifyReply } from 'fastify';
import { supabase } from '../../services/supabase';

// Helper to validate admin role
const isAdmin = async (userId: string) => {
    const { data: profile } = await supabase
        .from('users')
        .select('role')
        .eq('id', userId)
        .single();
    return profile?.role === 'admin';
};

export const getAdminDashboardStats = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    if (!(await isAdmin(user.sub))) return reply.code(403).send({ error: 'Access Denied' });

    // Parallel counts
    const [ordersCount, vendorsCount, usersCount, pendingVendorsCount] = await Promise.all([
        supabase.from('orders').select('*', { count: 'exact', head: true }),
        supabase.from('vendors').select('*', { count: 'exact', head: true }),
        supabase.from('users').select('*', { count: 'exact', head: true }),
        supabase.from('vendors').select('*', { count: 'exact', head: true }).eq('status', 'pending')
    ]);

    // Active orders in last 24h
    const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
    const { count: activeOrders } = await supabase
        .from('orders')
        .select('*', { count: 'exact', head: true })
        .gte('created_at', oneDayAgo);

    return reply.send({
        stats: {
            totalOrders: ordersCount.count,
            totalVendors: vendorsCount.count,
            totalUsers: usersCount.count,
            pendingVendors: pendingVendorsCount.count,
            activeOrdersLast24h: activeOrders
        }
    });
};

export const getAllVendors = async (request: FastifyRequest, reply: FastifyReply) => {
    const { status } = request.query as any;
    let query = supabase.from('vendors').select('*').order('created_at', { ascending: false });
    if (status) query = query.eq('status', status);

    const { data, error } = await query;
    if (error) throw error;
    return reply.send(data);
};

export const updateVendorStatus = async (request: FastifyRequest, reply: FastifyReply) => {
    const { id } = request.params as any;
    const { status, reason } = request.body as any;

    if (!['active', 'inactive', 'rejected', 'pending'].includes(status)) {
        return reply.code(400).send({ error: 'Invalid status' });
    }

    if (status === 'rejected' && (!reason || reason.length < 10)) {
        return reply.code(400).send({ error: 'A minimum 10-character reason is required for rejection' });
    }

    const { data: vendor, error: fetchError } = await supabase
        .from('vendors')
        .select('*')
        .eq('id', id)
        .single();

    if (fetchError || !vendor) return reply.code(404).send({ error: 'Vendor not found' });

    const { data, error } = await supabase
        .from('vendors')
        .update({ status, updated_at: new Date().toISOString() })
        .eq('id', id)
        .select()
        .single();

    if (error) throw error;

    // Log the action with reason
    await supabase.from('admin_logs').insert({
        admin_id: (request.user as any).sub,
        action: 'UPDATE_VENDOR_STATUS',
        entity_id: id,
        details: { status, reason, previous_status: vendor.status }
    });

    return reply.send(data);
};

export const getAuditLogs = async (request: FastifyRequest, reply: FastifyReply) => {
    const { limit = 50, offset = 0 } = request.query as any;
    const { data, error } = await supabase
        .from('admin_logs')
        .select('*, admin:admin_id(id, name, email)')
        .order('created_at', { ascending: false })
        .range(Number(offset), Number(offset) + Number(limit) - 1);

    if (error) throw error;
    return reply.send(data);
};

export const getAllOrders = async (request: FastifyRequest, reply: FastifyReply) => {
    const { limit = 50, offset = 0 } = request.query as any;
    const { data, error, count } = await supabase
        .from('orders')
        .select('*, user:user_id(id, name), vendor:vendor_id(id, name)', { count: 'exact' })
        .order('created_at', { ascending: false })
        .range(Number(offset), Number(offset) + Number(limit) - 1);

    if (error) throw error;
    return reply.send({
        data,
        meta: {
            total: count,
            page: Math.floor(offset / limit) + 1,
            limit: Number(limit),
            totalPages: Math.ceil((count || 0) / limit),
            hasNextPage: Number(offset) + Number(limit) < (count || 0),
            hasPreviousPage: Number(offset) > 0
        }
    });
};

export const cancelOrder = async (request: FastifyRequest, reply: FastifyReply) => {
    const { id } = request.params as any;
    const { reason } = request.body as any;

    if (!reason || reason.length < 10) {
        return reply.code(400).send({ error: 'A minimum 10-character reason is required for cancellation' });
    }

    const { data: order, error: fetchError } = await supabase
        .from('orders')
        .select('*')
        .eq('id', id)
        .single();

    if (fetchError || !order) return reply.code(404).send({ error: 'Order not found' });

    const { data, error } = await supabase
        .from('orders')
        .update({ status: 'cancelled', updated_at: new Date().toISOString() })
        .eq('id', id)
        .select()
        .single();

    if (error) throw error;

    // Log action
    await supabase.from('admin_logs').insert({
        admin_id: (request.user as any).sub,
        action: 'CANCEL_ORDER',
        entity_id: id,
        details: { reason, previous_status: order.status }
    });

    return reply.send(data);
};

export const blockUser = async (request: FastifyRequest, reply: FastifyReply) => {
    const { id } = request.params as any;
    const { reason } = request.body as any;

    if (!reason || reason.length < 10) {
        return reply.code(400).send({ error: 'A minimum 10-character reason is required for blocking' });
    }

    const { data: profile } = await supabase.from('users').select('*').eq('id', id).single();
    if (!profile) return reply.code(404).send({ error: 'User not found' });

    const { data, error } = await supabase
        .from('users')
        .update({ role: 'blocked', updated_at: new Date().toISOString() })
        .eq('id', id)
        .select()
        .single();

    if (error) throw error;

    // Log action
    await supabase.from('admin_logs').insert({
        admin_id: (request.user as any).sub,
        action: 'BLOCK_USER',
        entity_id: id,
        details: { reason, previous_role: profile.role }
    });

    return reply.send(data);
};

export const getPayoutRecords = async (request: FastifyRequest, reply: FastifyReply) => {
    const { data, error } = await supabase
        .from('vendor_payouts')
        .select('*, vendor:vendor_id(id, name)')
        .order('created_at', { ascending: false });

    if (error) throw error;
    return reply.send(data);
};
