import { FastifyReply, FastifyRequest } from 'fastify';
import { supabase } from '../services/supabase';

type Paging = {
    page: number;
    limit: number;
    from: number;
    to: number;
};

const toNumber = (value: unknown, fallback: number) => {
    const parsed = Number(value);
    return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
};

const getPaging = (query: Record<string, unknown>, defaultLimit = 20): Paging => {
    const page = toNumber(query.page, 1);
    const limit = toNumber(query.limit, defaultLimit);
    const from = (page - 1) * limit;
    const to = from + limit - 1;
    return { page, limit, from, to };
};

const buildMeta = (page: number, limit: number, total: number) => {
    const totalPages = Math.ceil(total / limit) || 1;
    return {
        page,
        limit,
        total,
        totalPages,
        hasNextPage: page < totalPages,
        hasPreviousPage: page > 1,
    };
};

const httpError = (statusCode: number, message: string) => {
    const err = new Error(message) as Error & { statusCode: number };
    err.statusCode = statusCode;
    return err;
};

const asAmount = (value: unknown): number => {
    const num = typeof value === 'number' ? value : Number(value);
    return Number.isFinite(num) ? num : 0;
};

export const getPendingVendors = async (request: FastifyRequest, reply: FastifyReply) => {
    const { page, limit, from, to } = getPaging((request.query as Record<string, unknown>) || {});

    const { count, error: countError } = await supabase
        .from('vendors')
        .select('*', { count: 'exact', head: true })
        .eq('status', 'pending');

    if (countError) {
        throw countError;
    }

    const { data, error } = await supabase
        .from('vendors')
        .select('*, owner:users(name, email)')
        .eq('status', 'pending')
        .order('created_at', { ascending: false })
        .range(from, to);

    if (error) {
        throw error;
    }

    const total = count || 0;
    return reply.send({
        vendors: data || [],
        page,
        limit,
        total,
        meta: buildMeta(page, limit, total),
    });
};

export const approveVendor = async (request: FastifyRequest, reply: FastifyReply) => {
    const { id } = request.params as { id: string };
    const { error } = await supabase.from('vendors').update({ status: 'approved' }).eq('id', id);
    if (error) {
        throw error;
    }
    return reply.send({ message: `Vendor ${id} approved successfully` });
};

export const rejectVendor = async (request: FastifyRequest, reply: FastifyReply) => {
    const { id } = request.params as { id: string };
    const { reason } = (request.body as { reason?: string }) || {};
    if (!reason) {
        throw httpError(400, 'Reason is required');
    }

    const { error } = await supabase.from('vendors').update({ status: 'rejected' }).eq('id', id);
    if (error) {
        throw error;
    }
    return reply.send({ message: `Vendor ${id} rejected successfully` });
};

export const getAdminOrders = async (request: FastifyRequest, reply: FastifyReply) => {
    const query = (request.query as Record<string, unknown>) || {};
    const status = typeof query.status === 'string' ? query.status : undefined;
    const { page, limit, from, to } = getPaging(query, 20);

    let countQuery = supabase.from('orders').select('*', { count: 'exact', head: true });
    if (status) {
        countQuery = countQuery.eq('status', status);
    }
    const { count, error: countError } = await countQuery;
    if (countError) {
        throw countError;
    }

    const baseQuery = supabase
        .from('orders')
        .select('*, users(name, email), vendors(name), order_items(quantity, unit_price)')
        .order('created_at', { ascending: false })
        .range(from, to);

    const { data, error } = status ? await baseQuery.eq('status', status) : await baseQuery;
    if (error) {
        throw error;
    }

    const total = count || 0;
    return reply.send({
        orders: data || [],
        page,
        limit,
        total,
        meta: buildMeta(page, limit, total),
    });
};

export const cancelAdminOrder = async (request: FastifyRequest, reply: FastifyReply) => {
    const { id } = request.params as { id: string };
    const { reason } = (request.body as { reason?: string }) || {};
    if (!reason) {
        throw httpError(400, 'Reason is required');
    }

    const { error } = await supabase
        .from('orders')
        .update({ status: 'cancelled', updated_at: new Date().toISOString() })
        .eq('id', id);

    if (error) {
        throw error;
    }

    return reply.send({ message: `Order ${id} cancelled successfully` });
};

export const getAdminUsers = async (request: FastifyRequest, reply: FastifyReply) => {
    const query = (request.query as Record<string, unknown>) || {};
    const { page, limit, from, to } = getPaging(query, 20);

    const { count, error: countError } = await supabase.from('users').select('*', { count: 'exact', head: true });
    if (countError) {
        throw countError;
    }

    const { data, error } = await supabase
        .from('users')
        .select('id, name, email, role, created_at')
        .order('created_at', { ascending: false })
        .range(from, to);

    if (error) {
        throw error;
    }

    const authUsersResp = await supabase.auth.admin.listUsers({ page, perPage: limit });
    if (authUsersResp.error) {
        throw authUsersResp.error;
    }

    const authUsers = authUsersResp.data?.users || [];
    const blockedById = new Map(
        authUsers.map((user: any) => [
            user.id,
            Boolean(user?.user_metadata?.is_blocked),
        ]),
    );

    const users = (data || []).map((user: any) => ({
        ...user,
        blocked: blockedById.get(user.id) || false,
    }));

    const total = count || 0;
    return reply.send({
        users,
        page,
        limit,
        total,
        meta: buildMeta(page, limit, total),
    });
};

export const blockAdminUser = async (request: FastifyRequest, reply: FastifyReply) => {
    const { id } = request.params as { id: string };
    const { blocked, reason } = (request.body as { blocked?: boolean; reason?: string }) || {};

    if (blocked && !reason) {
        throw httpError(400, 'Reason is required');
    }

    const current = await supabase.auth.admin.getUserById(id);
    if (current.error) {
        throw current.error;
    }

    const existingMeta = (current.data?.user as any)?.user_metadata || {};
    const user_metadata = {
        ...existingMeta,
        is_blocked: Boolean(blocked),
    };

    const update = await supabase.auth.admin.updateUserById(id, { user_metadata });
    if (update.error) {
        throw update.error;
    }

    return reply.send({ message: `User ${id} ${blocked ? 'blocked' : 'unblocked'} successfully` });
};

export const updateAdminUserRole = async (request: FastifyRequest, reply: FastifyReply) => {
    const { id } = request.params as { id: string };
    const { role } = request.body as { role: string };

    const { error } = await supabase.from('users').update({ role }).eq('id', id);
    if (error) {
        throw error;
    }

    const current = await supabase.auth.admin.getUserById(id);
    if (current.error) {
        throw current.error;
    }

    const existingMeta = (current.data?.user as any)?.user_metadata || {};
    const user_metadata = {
        ...existingMeta,
        role,
    };

    const update = await supabase.auth.admin.updateUserById(id, { user_metadata });
    if (update.error) {
        throw update.error;
    }

    return reply.send({ message: `User ${id} role updated to ${role} successfully` });
};

export const getFinanceSummary = async (_request: FastifyRequest, reply: FastifyReply) => {
    const { data, error } = await supabase
        .from('orders')
        .select('total_amount, created_at, status')
        .eq('status', 'completed');

    if (error) {
        throw error;
    }

    const orders = (data || []) as Array<{ total_amount: unknown; created_at: string }>;
    const now = new Date();
    const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const monthAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

    let total_revenue = 0;
    let today_revenue = 0;
    let week_revenue = 0;
    let month_revenue = 0;

    for (const order of orders) {
        const amount = asAmount(order.total_amount);
        const createdAt = new Date(order.created_at);
        total_revenue += amount;
        if (createdAt >= startOfToday) {
            today_revenue += amount;
        }
        if (createdAt >= weekAgo) {
            week_revenue += amount;
        }
        if (createdAt >= monthAgo) {
            month_revenue += amount;
        }
    }

    return reply.send({
        summary: {
            total_revenue,
            today_revenue,
            week_revenue,
            month_revenue,
        },
    });
};

export const getDashboardSummary = async (_request: FastifyRequest, reply: FastifyReply) => {
    const [users, vendors, orders, completed] = await Promise.all([
        supabase.from('users').select('*', { count: 'exact', head: true }),
        supabase.from('vendors').select('*', { count: 'exact', head: true }),
        supabase.from('orders').select('*', { count: 'exact', head: true }),
        supabase.from('orders').select('total_amount, status').eq('status', 'completed'),
    ]);

    if (users.error) throw users.error;
    if (vendors.error) throw vendors.error;
    if (orders.error) throw orders.error;
    if (completed.error) throw completed.error;

    const completedOrders = completed.data || [];
    const revenue = completedOrders.reduce((sum: number, order: any) => sum + asAmount(order.total_amount), 0);

    return reply.send({
        summary: {
            total_users: users.count || 0,
            total_vendors: vendors.count || 0,
            active_orders: orders.count || 0,
            completed_orders: completedOrders.length,
            revenue,
        },
    });
};

export const getGlobalStats = async (_request: FastifyRequest, reply: FastifyReply) => {
    const [users, vendors, orders, completed] = await Promise.all([
        supabase.from('users').select('*', { count: 'exact', head: true }),
        supabase.from('vendors').select('*', { count: 'exact', head: true }),
        supabase.from('orders').select('*', { count: 'exact', head: true }),
        supabase.from('orders').select('total_amount').eq('status', 'completed'),
    ]);

    if (users.error) throw users.error;
    if (vendors.error) throw vendors.error;
    if (orders.error) throw orders.error;
    if (completed.error) throw completed.error;

    const revenue = (completed.data || []).reduce((sum: number, order: any) => sum + asAmount(order.total_amount), 0);

    return reply.send({
        stats: {
            users: users.count || 0,
            vendors: vendors.count || 0,
            orders: orders.count || 0,
            revenue,
            gmv: revenue,
        },
    });
};

export const getChartData = async (_request: FastifyRequest, reply: FastifyReply) => {
    const today = new Date();
    const start = new Date(today.getFullYear(), today.getMonth(), today.getDate() - 6);

    const { data, error } = await supabase
        .from('orders')
        .select('created_at, total_amount, status')
        .gte('created_at', start.toISOString())
        .order('created_at', { ascending: true });

    if (error) {
        throw error;
    }

    const dayLabel = (date: Date) =>
        new Intl.DateTimeFormat('en-US', { weekday: 'short' }).format(date);

    const chartData = Array.from({ length: 7 }, (_, index) => {
        const day = new Date(start.getFullYear(), start.getMonth(), start.getDate() + index);
        return {
            name: dayLabel(day),
            orders: 0,
            revenue: 0,
        };
    });

    for (const order of data || []) {
        const created = new Date((order as any).created_at);
        const label = dayLabel(created);
        const bucket = chartData.find((entry) => entry.name === label);
        if (!bucket) {
            continue;
        }

        bucket.orders += 1;
        if ((order as any).status === 'completed') {
            bucket.revenue += asAmount((order as any).total_amount);
        }
    }

    return reply.send({ chartData });
};

export const getFinancePayouts = async (_request: FastifyRequest, reply: FastifyReply) => {
    const { data, error } = await supabase
        .from('orders')
        .select('vendor_id, total_amount, status, vendors(name)')
        .eq('status', 'completed');

    if (error) {
        throw error;
    }

    const grouped = new Map<string, { vendor_id: string; vendor_name: string; total_orders: number; total_revenue: number }>();

    for (const row of data || []) {
        const vendorId = ((row as any).vendor_id || '') as string;
        if (!grouped.has(vendorId)) {
            grouped.set(vendorId, {
                vendor_id: vendorId,
                vendor_name: (row as any)?.vendors?.name || 'Unknown',
                total_orders: 0,
                total_revenue: 0,
            });
        }

        const entry = grouped.get(vendorId)!;
        entry.total_orders += 1;
        entry.total_revenue += asAmount((row as any).total_amount);
    }

    return reply.send({ payouts: Array.from(grouped.values()) });
};

export const getAdminAuditLogs = async (request: FastifyRequest, reply: FastifyReply) => {
    const query = (request.query as Record<string, unknown>) || {};
    const action = typeof query.action === 'string' ? query.action : undefined;
    const { page, limit, from, to } = getPaging(query, 20);

    let countQuery = supabase.from('admin_logs').select('*', { count: 'exact', head: true });
    if (action) {
        countQuery = countQuery.eq('action_performed', action);
    }
    const { count, error: countError } = await countQuery;
    if (countError) {
        throw countError;
    }

    const baseQuery = supabase
        .from('admin_logs')
        .select('*')
        .order('created_at', { ascending: false })
        .range(from, to);
    const { data, error } = action ? await baseQuery.eq('action_performed', action) : await baseQuery;
    if (error) {
        throw error;
    }

    const total = count || 0;
    return reply.send({
        logs: data || [],
        page,
        limit,
        total,
        meta: buildMeta(page, limit, total),
    });
};

export const getAdminSettings = async (_request: FastifyRequest, reply: FastifyReply) => {
    return reply.send({
        settings: {
            commission_rate: 10,
            delivery_fee: 20,
            support_email: 'support@example.com',
        },
    });
};

export const updateAdminSettings = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = (request.user as { role?: string } | undefined) || {};
    if (user.role !== 'super_admin') {
        throw httpError(403, 'Only super admin can update settings');
    }

    return reply.send({ message: 'Settings updated', settings: request.body || {} });
};
