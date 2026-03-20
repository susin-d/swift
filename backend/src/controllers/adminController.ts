import { FastifyRequest, FastifyReply } from 'fastify';
import { supabase } from '../services/supabase';
import { createNotification } from '../services/notificationService';
import { buildPaginationMeta, parsePagination } from '../utils/pagination';

type AdminSettings = {
    commission_rate: number;
    delivery_fee: number;
};

let inMemoryAdminSettings: AdminSettings = {
    commission_rate: 12,
    delivery_fee: 25,
};

const logAdminAction = async (
    request: FastifyRequest,
    action: string,
    targetId?: string,
    reason?: string
) => {
    try {
        const adminId = (request.user as any)?.sub;
        if (!adminId) return;

        await supabase.from('admin_logs').insert({
            admin_id: adminId,
            action_performed: action,
            target_id: targetId || null,
            reason: reason || null,
        });
    } catch (err) {
        console.warn('admin log insert failed:', err);
    }
};

export const getGlobalStats = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
        const { count: userCount } = await supabase.from('users').select('*', { count: 'exact', head: true });
        const { count: vendorCount } = await supabase.from('vendors').select('*', { count: 'exact', head: true });
        const { count: orderCount } = await supabase.from('orders').select('*', { count: 'exact', head: true });

        // Calculate GMV (Gross Merchandise Value) from completed orders
        const { data: orders } = await supabase
            .from('orders')
            .select('total_amount')
            .eq('status', 'completed');

        const gmv = orders?.reduce((sum, order) => sum + Number(order.total_amount), 0) || 0;

        return reply.send({
            stats: {
                users: userCount || 0,
                vendors: vendorCount || 0,
                orders: orderCount || 0,
                revenue: gmv,
                gmv: gmv,
            }
        });
    } catch (err: any) {
        console.error('getGlobalStats error:', err);
        throw err;
    }
};

export const getDashboardSummary = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
        const { count: userCount } = await supabase.from('users').select('*', { count: 'exact', head: true });
        const { count: vendorCount } = await supabase.from('vendors').select('*', { count: 'exact', head: true });
        const { count: orderCount } = await supabase.from('orders').select('*', { count: 'exact', head: true });

        const { data: completedOrders } = await supabase
            .from('orders')
            .select('total_amount, status')
            .eq('status', 'completed');

        const revenue = completedOrders?.reduce((sum, order) => sum + Number(order.total_amount), 0) || 0;

        return reply.send({
            summary: {
                total_users: userCount || 0,
                total_vendors: vendorCount || 0,
                active_orders: orderCount || 0,
                completed_orders: completedOrders?.length || 0,
                revenue,
            }
        });
    } catch (err: any) {
        console.error('getDashboardSummary error:', err);
        throw err;
    }
};

export const getChartData = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
        // Fetch last 7 days of data
        const { data: orders, error } = await supabase
            .from('orders')
            .select('created_at, total_amount, status')
            .gte('created_at', new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString())
            .order('created_at', { ascending: true });

        if (error) throw error;

        // Group by day of week
        const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
        const chartData = days.map(day => ({ name: day, orders: 0, revenue: 0 }));

        orders?.forEach(order => {
            const dayName = days[new Date(order.created_at).getDay()];
            const dayObj = chartData.find(d => d.name === dayName);
            if (dayObj) {
                dayObj.orders += 1;
                if (order.status === 'completed') {
                    dayObj.revenue += Number(order.total_amount);
                }
            }
        });

        // Rotate so current day is at the end
        const todayIdx = new Date().getDay();
        const rotatedData = [
            ...chartData.slice(todayIdx + 1),
            ...chartData.slice(0, todayIdx + 1)
        ];

        return reply.send({ chartData: rotatedData });
    } catch (err: any) {
        console.error('getChartData error:', err);
        throw err;
    }
};

export const getPendingVendors = async (request: FastifyRequest, reply: FastifyReply) => {
    const query = request.query as {
        page?: string;
        limit?: string;
    };
    const { page, limit, from, to } = parsePagination(query);

    try {
        const { count, error: countError } = await supabase
            .from('vendors')
            .select('*', { count: 'exact', head: true })
            .eq('status', 'pending');

        if (countError) {
            request.log.warn({ err: countError }, 'admin.vendors.pending: status filter unavailable; returning empty list');
            return reply.send({
                vendors: [],
                page,
                limit,
                total: 0,
                meta: buildPaginationMeta(page, limit, 0),
            });
        }

        const withOwner = await supabase
            .from('vendors')
            .select('*, owner:users(name, email)')
            .eq('status', 'pending')
            .order('created_at', { ascending: false })
            .range(from, to);

        let data = withOwner.data as any[] | null;
        let error = withOwner.error;

        if (error) {
            const withoutOwner = await supabase
                .from('vendors')
                .select('*')
                .eq('status', 'pending')
                .order('created_at', { ascending: false })
                .range(from, to);
            data = withoutOwner.data as any[] | null;
            error = withoutOwner.error;
        }

        if (error) {
            request.log.warn({ err: error }, 'admin.vendors.pending: list query failed; returning empty list');
            return reply.send({
                vendors: [],
                page,
                limit,
                total: 0,
                meta: buildPaginationMeta(page, limit, 0),
            });
        }

        const total = count || 0;

        return reply.send({
            vendors: data ?? [],
            page,
            limit,
            total,
            meta: buildPaginationMeta(page, limit, total),
        });
    } catch (err: any) {
        console.error('getPendingVendors error:', err);
        throw err; // Caught by global error handler
    }
};

export const approveVendor = async (request: FastifyRequest, reply: FastifyReply) => {
    const { id } = request.params as { id: string };

    try {
        const { error } = await supabase
            .from('vendors')
            .update({ status: 'approved' } as any)
            .eq('id', id);

        if (error) throw error;

        await logAdminAction(request, 'approve_vendor', id);

        return reply.send({ message: `Vendor ${id} approved successfully` });
    } catch (err: any) {
        console.error('approveVendor error:', err);
        throw err; // Caught by global error handler
    }
};

export const rejectVendor = async (request: FastifyRequest, reply: FastifyReply) => {
    const { id } = request.params as { id: string };
    const { reason } = (request.body ?? {}) as { reason?: string };

    if (!reason?.trim()) {
        const err = new Error('`reason` is required to reject a vendor') as any;
        err.statusCode = 400;
        throw err;
    }

    try {
        const { error } = await supabase
            .from('vendors')
            .update({ status: 'rejected' } as any)
            .eq('id', id);

        if (error) throw error;

        await logAdminAction(request, 'reject_vendor', id, reason.trim());

        return reply.send({ message: `Vendor ${id} rejected successfully` });
    } catch (err: any) {
        console.error('rejectVendor error:', err);
        throw err; // Caught by global error handler
    }
};

export const getAdminOrders = async (request: FastifyRequest, reply: FastifyReply) => {
    const query = request.query as {
        page?: string;
        limit?: string;
        status?: string;
    };

    const { page, limit, from, to } = parsePagination(query);
    const status = query.status?.trim();

    try {
        let countQuery = supabase
            .from('orders')
            .select('*', { count: 'exact', head: true });

        if (status) {
            countQuery = countQuery.eq('status', status);
        }

        const { count, error: countError } = await countQuery;
        if (countError) throw countError;

        let ordersQuery = supabase
            .from('orders')
            .select('*, users(name, email), vendors(name), campus_buildings(name), order_items(quantity, unit_price)')
            .order('created_at', { ascending: false })
            .range(from, to);

        if (status) {
            ordersQuery = ordersQuery.eq('status', status);
        }

        const withCampus = await ordersQuery;
        let data = withCampus.data as any[] | null;
        let error = withCampus.error;

        if (error) {
            let fallbackQuery = supabase
                .from('orders')
                .select('*, users(name, email), vendors(name), order_items(quantity, unit_price)')
                .order('created_at', { ascending: false })
                .range(from, to);

            if (status) {
                fallbackQuery = fallbackQuery.eq('status', status);
            }

            const withoutCampus = await fallbackQuery;
            data = withoutCampus.data as any[] | null;
            error = withoutCampus.error;

            if (error) {
                let plainOrdersQuery = supabase
                    .from('orders')
                    .select('*')
                    .order('created_at', { ascending: false })
                    .range(from, to);

                if (status) {
                    plainOrdersQuery = plainOrdersQuery.eq('status', status);
                }

                const plainOrders = await plainOrdersQuery;
                data = plainOrders.data as any[] | null;
                error = plainOrders.error;
            }
        }

        if (error) throw error;

        const total = count || 0;

        return reply.send({
            orders: data ?? [],
            page,
            limit,
            total,
            meta: buildPaginationMeta(page, limit, total),
        });
    } catch (err: any) {
        console.error('getAdminOrders error:', err);
        throw err;
    }
};

export const cancelAdminOrder = async (request: FastifyRequest, reply: FastifyReply) => {
    const { id } = request.params as { id: string };
    const { reason } = (request.body ?? {}) as { reason?: string };

    if (!reason?.trim()) {
        const err = new Error('`reason` is required to cancel an order') as any;
        err.statusCode = 400;
        throw err;
    }

      try {
          const { data: order, error } = await supabase
              .from('orders')
              .update({ status: 'cancelled', updated_at: new Date().toISOString() })
              .eq('id', id)
              .select()
              .single();

          if (error) throw error;

          await logAdminAction(request, 'cancel_order', id, reason.trim());

          if (order?.user_id) {
              const compactId = id.substring(0, 8).toUpperCase();
              await createNotification({
                  userId: order.user_id,
                  audience: 'user',
                  type: 'order_cancelled',
                  title: 'Order cancelled by admin',
                  body: `Order #${compactId} was cancelled by support`,
                  metadata: { order_id: id, reason: reason.trim() },
              });
          }

          return reply.send({ message: `Order ${id} cancelled successfully` });
      } catch (err: any) {
        console.error('cancelAdminOrder error:', err);
        throw err;
    }
};

export const getFinanceSummary = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
        const { data: completedOrders, error } = await supabase
            .from('orders')
            .select('total_amount, created_at, status')
            .eq('status', 'completed');

        if (error) throw error;

        const now = new Date();
        const dayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        const weekStart = new Date(dayStart);
        weekStart.setDate(dayStart.getDate() - 6);
        const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);

        let todayRevenue = 0;
        let weekRevenue = 0;
        let monthRevenue = 0;
        let totalRevenue = 0;

        for (const order of completedOrders ?? []) {
            const amount = Number((order as any).total_amount) || 0;
            const createdAt = new Date((order as any).created_at);

            totalRevenue += amount;
            if (createdAt >= dayStart) todayRevenue += amount;
            if (createdAt >= weekStart) weekRevenue += amount;
            if (createdAt >= monthStart) monthRevenue += amount;
        }

        return reply.send({
            summary: {
                today_revenue: todayRevenue,
                week_revenue: weekRevenue,
                month_revenue: monthRevenue,
                total_revenue: totalRevenue,
            },
        });
    } catch (err: any) {
        console.error('getFinanceSummary error:', err);
        throw err;
    }
};

export const getFinancePayouts = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
        const { data: orders, error } = await supabase
            .from('orders')
            .select('vendor_id, total_amount, status, vendors(name)')
            .eq('status', 'completed');

        if (error) throw error;

        const grouped = new Map<string, { vendor_id: string; vendor_name: string; total_revenue: number; total_orders: number; status: string }>();

        for (const order of orders ?? []) {
            const o: any = order;
            const vendorId = o.vendor_id as string;
            const vendorName = o.vendors?.name ?? 'Unknown vendor';
            const amount = Number(o.total_amount) || 0;

            if (!grouped.has(vendorId)) {
                grouped.set(vendorId, {
                    vendor_id: vendorId,
                    vendor_name: vendorName,
                    total_revenue: 0,
                    total_orders: 0,
                    status: 'pending',
                });
            }

            const entry = grouped.get(vendorId)!;
            entry.total_orders += 1;
            entry.total_revenue += amount;
        }

        const payouts = Array.from(grouped.values()).sort((a, b) => b.total_revenue - a.total_revenue);
        return reply.send({ payouts });
    } catch (err: any) {
        console.error('getFinancePayouts error:', err);
        throw err;
    }
};

export const exportFinancePayouts = async (_request: FastifyRequest, reply: FastifyReply) => {
    try {
        const { data: orders, error } = await supabase
            .from('orders')
            .select('vendor_id, total_amount, status, vendors(name)')
            .eq('status', 'completed');

        if (error) throw error;

        const grouped = new Map<string, { vendor_id: string; vendor_name: string; total_revenue: number; total_orders: number; status: string }>();

        for (const order of orders ?? []) {
            const o: any = order;
            const vendorId = o.vendor_id as string;
            const vendorName = o.vendors?.name ?? 'Unknown vendor';
            const amount = Number(o.total_amount) || 0;

            if (!grouped.has(vendorId)) {
                grouped.set(vendorId, {
                    vendor_id: vendorId,
                    vendor_name: vendorName,
                    total_revenue: 0,
                    total_orders: 0,
                    status: 'pending',
                });
            }

            const entry = grouped.get(vendorId)!;
            entry.total_orders += 1;
            entry.total_revenue += amount;
        }

        const payouts = Array.from(grouped.values()).sort((a, b) => b.total_revenue - a.total_revenue);
        const header = 'vendor_id,vendor_name,total_revenue,total_orders,status';
        const lines = payouts.map((p) =>
            [
                p.vendor_id,
                `"${p.vendor_name.replace(/"/g, '""')}"`,
                p.total_revenue.toFixed(2),
                p.total_orders,
                p.status,
            ].join(',')
        );
        const csv = [header, ...lines].join('\n');

        return reply
            .header('Content-Type', 'text/csv')
            .header('Content-Disposition', 'attachment; filename="payouts.csv"')
            .send(csv);
    } catch (err: any) {
        console.error('exportFinancePayouts error:', err);
        throw err;
    }
};

export const getAdminUsers = async (request: FastifyRequest, reply: FastifyReply) => {
    const query = request.query as {
        page?: string;
        limit?: string;
    };

    const { page, limit, from, to } = parsePagination(query);

    try {
        const { count, error: countError } = await supabase
            .from('users')
            .select('*', { count: 'exact', head: true });

        if (countError) throw countError;

        const { data, error } = await supabase
            .from('users')
            .select('id, name, email, role, created_at')
            .order('created_at', { ascending: false })
            .range(from, to);

        if (error) throw error;

        let blockedById: Record<string, boolean> = {};
        try {
            const authPage = Math.max(1, page);
            const { data: authData } = await supabase.auth.admin.listUsers({
                page: authPage,
                perPage: Math.max(limit, 20),
            });

            const users = authData?.users ?? [];
            blockedById = users.reduce((acc: Record<string, boolean>, user: any) => {
                const metaBlocked = !!user?.user_metadata?.is_blocked;
                const bannedUntil = !!user?.banned_until;
                acc[user.id] = metaBlocked || bannedUntil;
                return acc;
            }, {});
        } catch (authErr) {
            console.warn('getAdminUsers: listUsers metadata lookup failed; defaulting blocked=false');
        }

        const users = (data ?? []).map((u: any) => ({
            ...u,
            blocked: blockedById[u.id] ?? false,
        }));

        const total = count || 0;

        return reply.send({
            users,
            page,
            limit,
            total,
            meta: buildPaginationMeta(page, limit, total),
        });
    } catch (err: any) {
        console.error('getAdminUsers error:', err);
        throw err;
    }
};

export const blockAdminUser = async (request: FastifyRequest, reply: FastifyReply) => {
    const { id } = request.params as { id: string };
    const { blocked, reason } = (request.body ?? {}) as { blocked?: boolean; reason?: string };

    if (typeof blocked !== 'boolean') {
        const err = new Error('`blocked` boolean is required') as any;
        err.statusCode = 400;
        throw err;
    }

    if (blocked && !reason?.trim()) {
        const err = new Error('`reason` is required when blocking a user') as any;
        err.statusCode = 400;
        throw err;
    }

    try {
        const { data: authUserData, error: fetchError } = await supabase.auth.admin.getUserById(id);
        if (fetchError) throw fetchError;

        const currentMeta = authUserData?.user?.user_metadata ?? {};
        const { error: authError } = await supabase.auth.admin.updateUserById(id, {
            user_metadata: {
                ...currentMeta,
                is_blocked: blocked,
            },
        });

        if (authError) throw authError;

        await logAdminAction(request, blocked ? 'block_user' : 'unblock_user', id, blocked ? reason?.trim() : undefined);

        return reply.send({
            message: `User ${id} ${blocked ? 'blocked' : 'unblocked'} successfully`,
        });
    } catch (err: any) {
        console.error('blockAdminUser error:', err);
        throw err;
    }
};

export const updateAdminUserRole = async (request: FastifyRequest, reply: FastifyReply) => {
    const { id } = request.params as { id: string };
    const { role } = request.body as { role: string };

    if (!['user', 'vendor', 'admin'].includes(role)) {
        const err = new Error('Invalid role specified') as any;
        err.statusCode = 400;
        throw err;
    }

    try {
        const { error: profileError } = await supabase
            .from('users')
            .update({ role })
            .eq('id', id);

        if (profileError) throw profileError;

        const { data: authUserData, error: fetchError } = await supabase.auth.admin.getUserById(id);
        if (fetchError) throw fetchError;

        const currentMeta = authUserData?.user?.user_metadata ?? {};
        const { error: authError } = await supabase.auth.admin.updateUserById(
            id,
            { user_metadata: { ...currentMeta, role } }
        );

        if (authError) {
            console.error('Auth metadata sync failed (non-fatal):', authError);
        }

        await logAdminAction(request, 'update_user_role', id);

        return reply.send({ message: `User ${id} role updated to ${role} successfully` });
    } catch (err: any) {
        console.error('updateAdminUserRole error:', err);
        throw err;
    }
};

export const updateUserRole = async (request: FastifyRequest, reply: FastifyReply) => {
    const { userId, role } = request.body as { userId: string, role: string };

    if (!['user', 'vendor', 'admin'].includes(role)) {
        const err = new Error('Invalid role specified') as any;
        err.statusCode = 400;
        throw err;
    }

    try {
        // Update public.users table
        const { error: profileError } = await supabase
            .from('users')
            .update({ role })
            .eq('id', userId);

        if (profileError) throw profileError;

        // Update auth.users metadata for consistency
        const { error: authError } = await supabase.auth.admin.updateUserById(
            userId,
            { user_metadata: { role } }
        );

        if (authError) {
            console.error('Auth metadata sync failed (non-fatal):', authError);
            // We still proceed since public.users is the source of truth for our app RBAC
        }

        return reply.send({ message: `User ${userId} role updated to ${role} successfully` });
    } catch (err: any) {
        console.error('updateUserRole error:', err);
        throw err;
    }
};

export const getAdminAuditLogs = async (request: FastifyRequest, reply: FastifyReply) => {
    const query = request.query as {
        page?: string;
        limit?: string;
        action?: string;
        admin_id?: string;
    };

    const { page, limit, from, to } = parsePagination(query);

    try {
        const { error: tableProbeError } = await supabase
            .from('admin_logs')
            .select('id', { head: true, count: 'exact' })
            .limit(1);

        if (tableProbeError) {
            request.log.warn({ err: tableProbeError }, 'admin.audit: admin_logs unavailable; returning empty list');
            return reply.send({
                logs: [],
                page,
                limit,
                total: 0,
                meta: buildPaginationMeta(page, limit, 0),
            });
        }

        let countQuery = supabase
            .from('admin_logs')
            .select('*', { count: 'exact', head: true });

        let dataQuery = supabase
            .from('admin_logs')
            .select('id, admin_id, action_performed, target_id, reason, created_at')
            .order('created_at', { ascending: false })
            .range(from, to);

        if (query.action) {
            countQuery = countQuery.eq('action_performed', query.action);
            dataQuery = dataQuery.eq('action_performed', query.action);
        }

        if (query.admin_id) {
            countQuery = countQuery.eq('admin_id', query.admin_id);
            dataQuery = dataQuery.eq('admin_id', query.admin_id);
        }

        const { count, error: countError } = await countQuery;
        if (countError) throw countError;

        const { data, error } = await dataQuery;
        if (error) throw error;

        const total = count || 0;

        return reply.send({
            logs: data ?? [],
            page,
            limit,
            total,
            meta: buildPaginationMeta(page, limit, total),
        });
    } catch (err: any) {
        console.error('getAdminAuditLogs error:', err);
        throw err;
    }
};

export const getAdminSettings = async (_request: FastifyRequest, reply: FastifyReply) => {
    return reply.send({ settings: inMemoryAdminSettings });
};

export const updateAdminSettings = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const superAdminEmail = process.env.SUPER_ADMIN_EMAIL;

    const isSuperAdmin = user?.role === 'admin' && !!superAdminEmail && user?.email === superAdminEmail;
    if (!isSuperAdmin) {
        const err = new Error('Only super_admin can update settings') as any;
        err.statusCode = 403;
        throw err;
    }

    const payload = request.body as Partial<AdminSettings>;
    const nextCommission = Number(payload.commission_rate);
    const nextDeliveryFee = Number(payload.delivery_fee);

    if (!Number.isFinite(nextCommission) || !Number.isFinite(nextDeliveryFee)) {
        const err = new Error('commission_rate and delivery_fee must be numeric') as any;
        err.statusCode = 400;
        throw err;
    }

    inMemoryAdminSettings = {
        commission_rate: nextCommission,
        delivery_fee: nextDeliveryFee,
    };

    await logAdminAction(request, 'update_settings');

    return reply.send({ settings: inMemoryAdminSettings });
};

export const createVendorAccount = async (request: FastifyRequest, reply: FastifyReply) => {
    const { email, password, name, description, image_url } = request.body as any;

    if (!email || !password || !name) {
        const err = new Error('Email, password, and name are required') as any;
        err.statusCode = 400;
        throw err;
    }

    try {
        // 1. Create Supabase Auth User
        const { data: authData, error: authError } = await supabase.auth.admin.createUser({
            email,
            password,
            email_confirm: true,
            user_metadata: { name, role: 'vendor' }
        });

        if (authError) throw authError;

        const userId = authData.user.id;

        // 2. Create public.users record
        const { error: userError } = await supabase
            .from('users')
            .insert({
                id: userId,
                name,
                email,
                role: 'vendor'
            });

        if (userError) throw userError;

        // 3. Create public.vendors record
        const { data: vendorData, error: vendorError } = await supabase
            .from('vendors')
            .insert({
                owner_id: userId,
                name,
                description,
                image_url,
                is_open: true
            })
            .select()
            .single();

        if (vendorError) throw vendorError;

        return reply.code(201).send({
            message: 'Vendor account created successfully',
            vendor: vendorData,
            userId: userId
        });
    } catch (err: any) {
        console.error('createVendorAccount error:', err);
        throw err;
    }
};
