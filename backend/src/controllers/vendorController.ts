import { FastifyRequest, FastifyReply } from 'fastify';
import { randomUUID } from 'crypto';
import { supabase } from '../services/supabase';

const resolveVendor = async (userSub: string) => {
    const { data: vendor, error } = await supabase
        .from('vendors')
        .select('id, is_open')
        .eq('owner_id', userSub)
        .single();

    if (error || !vendor) {
        const err = new Error('Vendor profile not found') as any;
        err.statusCode = 404;
        throw err;
    }

    return vendor;
};

const amount = (value: unknown) => Number(value ?? 0) || 0;
const staffStatuses = new Set(['active', 'inactive', 'suspended']);

const trimToNull = (value: unknown) => {
    if (typeof value !== 'string') return null;
    const next = value.trim();
    return next.length > 0 ? next : null;
};

const logVendorMutation = async (
    actorUserId: string,
    action: string,
    targetId: string | null,
    reason: string,
) => {
    try {
        await supabase
            .from('admin_logs')
            .insert({
                admin_id: actorUserId,
                action_performed: action,
                target_id: targetId,
                reason,
            });
    } catch {
        // Non-blocking audit write.
    }
};

export const updateVendorProfile = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const { name, description, image_url, is_open } = request.body as any;

    const { data, error } = await supabase
        .from('vendors')
        .update({ name, description, image_url, is_open })
        .eq('owner_id', user.sub)
        .select()
        .single();

    if (error) throw error;

    return reply.send({ vendor: data });
};

export const getMyVendorProfile = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;

    const { data, error } = await supabase
        .from('vendors')
        .select('*')
        .eq('owner_id', user.sub)
        .single();

    if (error) {
        const err = new Error('Vendor profile not found') as any;
        err.statusCode = 404;
        throw err;
    }

    return reply.send({ vendor: data });
};

export const getAllVendors = async (request: FastifyRequest, reply: FastifyReply) => {
    const { data, error } = await supabase
        .from('vendors')
        .select('*, reviews(count)')
        .order('name', { ascending: true });

    if (error) throw error;
    const mapped = (data ?? []).map((v: any) => {
        const reviewCount = v.reviews?.[0]?.count ?? 0;
        const { reviews: _reviews, ...rest } = v;
        return { ...rest, review_count: Number(reviewCount) };
    });
    return reply.send(mapped);
};

export const getVendorStats = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;

    // 1. Get vendor ID
    const { data: vendor, error: vendorError } = await supabase
        .from('vendors')
        .select('id')
        .eq('owner_id', user.sub)
        .single();

    if (vendorError || !vendor) {
        const err = new Error('Vendor profile not found') as any;
        err.statusCode = 404;
        throw err;
    }

    // 2. Fetch order stats for this vendor
    const { data: stats, error: statsError } = await supabase
        .from('orders')
        .select('total_amount, status')
        .eq('vendor_id', vendor.id);

    if (statsError) throw statsError;

    const totalOrders = stats.length;
    const completedOrders = stats.filter(o => o.status === 'completed' || o.status === 'delivered').length;
    const gmv = stats.reduce((sum, o) => sum + Number(o.total_amount), 0);

    return reply.send({
        stats: {
            totalOrders,
            completedOrders,
            gmv
        }
    });
};

export const getVendorStoreControls = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;

    const vendor = await resolveVendor(user.sub);

    const { data: settings } = await supabase
        .from('vendor_settings')
        .select('preparation_time_avg, auto_accept_orders, busy_mode_enabled, busy_mode_message, holiday_until')
        .eq('vendor_id', vendor.id)
        .maybeSingle();

    return reply.send({
        controls: {
            vendor_id: vendor.id,
            is_open: vendor.is_open === true,
            auto_accept_orders: settings?.auto_accept_orders === true,
            preparation_time_avg: Number(settings?.preparation_time_avg ?? 15),
            busy_mode_enabled: settings?.busy_mode_enabled === true,
            busy_mode_message: settings?.busy_mode_message ?? null,
            holiday_until: settings?.holiday_until ?? null,
        },
    });
};

export const updateVendorStoreControls = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const body = request.body as any;

    const vendor = await resolveVendor(user.sub);

    const vendorPatch: Record<string, unknown> = {};
    if (typeof body?.is_open === 'boolean') {
        vendorPatch.is_open = body.is_open;
    }

    if (Object.keys(vendorPatch).length > 0) {
        const { error: vendorPatchError } = await supabase
            .from('vendors')
            .update(vendorPatch)
            .eq('id', vendor.id);
        if (vendorPatchError) throw vendorPatchError;
    }

    const nextPreparation = Number(body?.preparation_time_avg ?? 15);
    const normalizedPreparation = Number.isNaN(nextPreparation)
        ? 15
        : Math.min(90, Math.max(5, Math.round(nextPreparation)));
    const holidayUntilRaw = typeof body?.holiday_until === 'string' ? body.holiday_until.trim() : '';
    const holidayUntil = holidayUntilRaw.length > 0 ? holidayUntilRaw : null;

    const upsertPayload = {
        vendor_id: vendor.id,
        preparation_time_avg: normalizedPreparation,
        auto_accept_orders: body?.auto_accept_orders === true,
        busy_mode_enabled: body?.busy_mode_enabled === true,
        busy_mode_message: typeof body?.busy_mode_message === 'string' ? body.busy_mode_message.trim() || null : null,
        holiday_until: holidayUntil,
    };

    const { error: upsertError } = await supabase
        .from('vendor_settings')
        .upsert(upsertPayload, { onConflict: 'vendor_id' });

    if (upsertError) throw upsertError;

    return getVendorStoreControls(request, reply);
};

export const getVendorFinanceEarnings = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const vendor = await resolveVendor(user.sub);

    const { data: orders, error } = await supabase
        .from('orders')
        .select('status, total_amount, created_at')
        .eq('vendor_id', vendor.id)
        .order('created_at', { ascending: false });

    if (error) throw error;

    const rows = orders || [];
    const now = new Date();
    const todayKey = now.toISOString().slice(0, 10);

    const completedRevenue = rows
        .filter((o: any) => ['completed', 'delivered'].includes((o.status || '').toLowerCase()))
        .reduce((sum: number, o: any) => sum + amount(o.total_amount), 0);

    const pendingRevenue = rows
        .filter((o: any) => !['completed', 'delivered', 'cancelled'].includes((o.status || '').toLowerCase()))
        .reduce((sum: number, o: any) => sum + amount(o.total_amount), 0);

    const todayRevenue = rows
        .filter((o: any) => (o.created_at || '').slice(0, 10) === todayKey)
        .reduce((sum: number, o: any) => sum + amount(o.total_amount), 0);

    return reply.send({
        earnings: {
            total_completed_revenue: completedRevenue,
            pending_revenue: pendingRevenue,
            today_revenue: todayRevenue,
            total_orders: rows.length,
            completed_orders: rows.filter((o: any) => ['completed', 'delivered'].includes((o.status || '').toLowerCase())).length,
        },
    });
};

export const getVendorFinancePayouts = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const vendor = await resolveVendor(user.sub);

    const { data: orders, error } = await supabase
        .from('orders')
        .select('status, total_amount, created_at')
        .eq('vendor_id', vendor.id)
        .in('status', ['completed', 'delivered'])
        .order('created_at', { ascending: false });

    if (error) throw error;

    const grouped = new Map<string, { period: string; total_amount: number; orders: number; status: string }>();
    for (const row of orders || []) {
        const d = new Date((row as any).created_at || Date.now());
        const key = `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, '0')}`;
        const bucket = grouped.get(key) || { period: key, total_amount: 0, orders: 0, status: 'processing' };
        bucket.total_amount += amount((row as any).total_amount);
        bucket.orders += 1;
        grouped.set(key, bucket);
    }

    return reply.send({ payouts: Array.from(grouped.values()) });
};

export const getVendorFinanceTransactions = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const vendor = await resolveVendor(user.sub);

    const { data: vendorOrders, error: orderError } = await supabase
        .from('orders')
        .select('id, total_amount, status, created_at')
        .eq('vendor_id', vendor.id)
        .order('created_at', { ascending: false })
        .limit(100);

    if (orderError) throw orderError;

    const orderIds = (vendorOrders || []).map((o: any) => o.id);
    if (orderIds.length === 0) {
        return reply.send({ transactions: [] });
    }

    const { data: payments, error: paymentError } = await supabase
        .from('payments')
        .select('id, order_id, amount, status, provider_ref')
        .in('order_id', orderIds)
        .order('id', { ascending: false });

    if (paymentError) throw paymentError;

    const orderMap = new Map((vendorOrders || []).map((o: any) => [o.id, o]));
    const transactions = (payments || []).map((payment: any) => ({
        id: payment.id,
        order_id: payment.order_id,
        amount: amount(payment.amount),
        status: payment.status,
        provider_ref: payment.provider_ref,
        order_status: orderMap.get(payment.order_id)?.status || 'unknown',
        order_total: amount(orderMap.get(payment.order_id)?.total_amount),
        created_at: orderMap.get(payment.order_id)?.created_at || null,
    }));

    return reply.send({ transactions });
};

export const getVendorFinanceTaxReports = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const vendor = await resolveVendor(user.sub);

    const { data: completedOrders, error } = await supabase
        .from('orders')
        .select('id, total_amount, created_at')
        .eq('vendor_id', vendor.id)
        .in('status', ['completed', 'delivered']);

    if (error) throw error;

    const taxableTurnover = (completedOrders || []).reduce((sum: number, row: any) => sum + amount(row.total_amount), 0);
    const estimatedGst = Number((taxableTurnover * 0.05).toFixed(2));
    const csv = ['order_id,total_amount,created_at', ...(completedOrders || []).map((o: any) => `${o.id},${amount(o.total_amount)},${o.created_at}`)].join('\n');

    return reply.send({
        tax_report: {
            taxable_turnover: taxableTurnover,
            estimated_gst: estimatedGst,
            order_count: (completedOrders || []).length,
            csv,
        },
    });
};

export const getVendorAnalyticsSales = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const vendor = await resolveVendor(user.sub);

    const { data: orders, error } = await supabase
        .from('orders')
        .select('created_at, total_amount')
        .eq('vendor_id', vendor.id)
        .order('created_at', { ascending: false })
        .limit(200);

    if (error) throw error;

    const byDay = new Map<string, { day: string; revenue: number; orders: number }>();
    for (const row of orders || []) {
        const day = (row as any).created_at?.slice(0, 10) || 'unknown';
        const bucket = byDay.get(day) || { day, revenue: 0, orders: 0 };
        bucket.revenue += amount((row as any).total_amount);
        bucket.orders += 1;
        byDay.set(day, bucket);
    }

    return reply.send({ metrics: Array.from(byDay.values()).slice(0, 14) });
};

export const getVendorAnalyticsPerformance = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const vendor = await resolveVendor(user.sub);

    const { data: orders, error } = await supabase
        .from('orders')
        .select('status')
        .eq('vendor_id', vendor.id);

    if (error) throw error;

    const total = (orders || []).length;
    const completed = (orders || []).filter((o: any) => ['completed', 'delivered'].includes((o.status || '').toLowerCase())).length;
    const cancelled = (orders || []).filter((o: any) => (o.status || '').toLowerCase() === 'cancelled').length;

    return reply.send({
        metrics: {
            total_orders: total,
            completion_rate: total === 0 ? 0 : Number(((completed / total) * 100).toFixed(2)),
            cancellation_rate: total === 0 ? 0 : Number(((cancelled / total) * 100).toFixed(2)),
        },
    });
};

export const getVendorAnalyticsPeakHours = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const vendor = await resolveVendor(user.sub);

    const { data: orders, error } = await supabase
        .from('orders')
        .select('created_at')
        .eq('vendor_id', vendor.id)
        .order('created_at', { ascending: false })
        .limit(300);

    if (error) throw error;

    const buckets: Record<string, number> = {};
    for (const row of orders || []) {
        const date = new Date((row as any).created_at || Date.now());
        const hour = `${String(date.getHours()).padStart(2, '0')}:00`;
        buckets[hour] = (buckets[hour] || 0) + 1;
    }

    return reply.send({ peak_hours: Object.entries(buckets).map(([hour, orders]) => ({ hour, orders })) });
};

export const getVendorAnalyticsTopItems = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const vendor = await resolveVendor(user.sub);

    const { data: orders, error: ordersError } = await supabase
        .from('orders')
        .select('id')
        .eq('vendor_id', vendor.id)
        .limit(200);

    if (ordersError) throw ordersError;

    const orderIds = (orders || []).map((o: any) => o.id);
    if (orderIds.length === 0) {
        return reply.send({ top_items: [] });
    }

    const { data: items, error: itemsError } = await supabase
        .from('order_items')
        .select('item_id, menu_item_id, quantity, unit_price')
        .in('order_id', orderIds);

    if (itemsError) throw itemsError;

    const grouped = new Map<string, { item_id: string; quantity: number; revenue: number }>();
    for (const item of items || []) {
        const id = (item as any).menu_item_id || (item as any).item_id;
        if (!id) continue;
        const bucket = grouped.get(id) || { item_id: id, quantity: 0, revenue: 0 };
        const qty = Number((item as any).quantity || 0);
        const price = amount((item as any).unit_price);
        bucket.quantity += qty;
        bucket.revenue += qty * price;
        grouped.set(id, bucket);
    }

    const top = Array.from(grouped.values()).sort((a, b) => b.quantity - a.quantity).slice(0, 10);
    return reply.send({ top_items: top });
};

export const getVendorStaffManagement = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const vendor = await resolveVendor(user.sub);

    const { data: staff, error } = await supabase
        .from('vendor_staff_members')
        .select('id, name, role_key, status, email, phone, created_at, updated_at')
        .eq('vendor_id', vendor.id)
        .order('created_at', { ascending: false });

    if (error) throw error;

    return reply.send({ staff: staff || [] });
};

export const createVendorStaffMember = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const body = request.body as any;
    const vendor = await resolveVendor(user.sub);

    const name = trimToNull(body?.name);
    const roleKey = trimToNull(body?.role_key) || trimToNull(body?.role);
    const status = (trimToNull(body?.status) || 'active').toLowerCase();

    if (!name) {
        const err = new Error('name is required') as any;
        err.statusCode = 400;
        throw err;
    }

    if (!roleKey) {
        const err = new Error('role_key is required') as any;
        err.statusCode = 400;
        throw err;
    }

    if (!staffStatuses.has(status)) {
        const err = new Error('status must be one of active|inactive|suspended') as any;
        err.statusCode = 400;
        throw err;
    }

    const now = new Date().toISOString();
    const { data, error } = await supabase
        .from('vendor_staff_members')
        .insert({
            vendor_id: vendor.id,
            name,
            role_key: roleKey,
            status,
            email: trimToNull(body?.email),
            phone: trimToNull(body?.phone),
            updated_at: now,
        })
        .select('id, name, role_key, status, email, phone, created_at, updated_at')
        .single();

    if (error) throw error;
    await logVendorMutation(user.sub, 'vendor.staff.member.create', data?.id || null, `Created staff member ${name}`);
    return reply.code(201).send({ staff: data });
};

export const updateVendorStaffMember = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const body = request.body as any;
    const { staffId } = request.params as any;
    const vendor = await resolveVendor(user.sub);

    const patch: Record<string, unknown> = {};
    const name = trimToNull(body?.name);
    const roleKey = trimToNull(body?.role_key) || trimToNull(body?.role);
    const statusRaw = trimToNull(body?.status);

    if (name !== null) patch.name = name;
    if (roleKey !== null) patch.role_key = roleKey;
    if (statusRaw !== null) {
        const status = statusRaw.toLowerCase();
        if (!staffStatuses.has(status)) {
            const err = new Error('status must be one of active|inactive|suspended') as any;
            err.statusCode = 400;
            throw err;
        }
        patch.status = status;
    }

    if (typeof body?.email === 'string') patch.email = trimToNull(body.email);
    if (typeof body?.phone === 'string') patch.phone = trimToNull(body.phone);

    if (Object.keys(patch).length === 0) {
        const err = new Error('At least one field must be provided') as any;
        err.statusCode = 400;
        throw err;
    }

    patch.updated_at = new Date().toISOString();

    const { data, error } = await supabase
        .from('vendor_staff_members')
        .update(patch)
        .eq('id', staffId)
        .eq('vendor_id', vendor.id)
        .select('id, name, role_key, status, email, phone, created_at, updated_at')
        .maybeSingle();

    if (error) throw error;
    if (!data) {
        const err = new Error('Staff member not found') as any;
        err.statusCode = 404;
        throw err;
    }

    await logVendorMutation(user.sub, 'vendor.staff.member.update', data.id, 'Updated staff member fields');
    return reply.send({ staff: data });
};

export const deleteVendorStaffMember = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const { staffId } = request.params as any;
    const vendor = await resolveVendor(user.sub);

    const { data, error } = await supabase
        .from('vendor_staff_members')
        .delete()
        .eq('id', staffId)
        .eq('vendor_id', vendor.id)
        .select('id')
        .maybeSingle();

    if (error) throw error;
    if (!data) {
        const err = new Error('Staff member not found') as any;
        err.statusCode = 404;
        throw err;
    }

    await logVendorMutation(user.sub, 'vendor.staff.member.delete', data.id, 'Deleted staff member');
    return reply.send({ success: true, id: data.id });
};

export const getVendorStaffInvitations = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const vendor = await resolveVendor(user.sub);

    const { data, error } = await supabase
        .from('vendor_staff_invitations')
        .select('id, email, role_key, status, invited_user_id, expires_at, accepted_at, created_at')
        .eq('vendor_id', vendor.id)
        .order('created_at', { ascending: false });

    if (error) throw error;
    return reply.send({ invitations: data || [] });
};

export const createVendorStaffInvitation = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const body = request.body as any;
    const vendor = await resolveVendor(user.sub);

    const email = trimToNull(body?.email);
    const roleKey = trimToNull(body?.role_key) || trimToNull(body?.role);
    const expiresInDays = Number(body?.expires_in_days ?? 7);

    if (!email || !email.includes('@')) {
        const err = new Error('valid email is required') as any;
        err.statusCode = 400;
        throw err;
    }

    if (!roleKey) {
        const err = new Error('role_key is required') as any;
        err.statusCode = 400;
        throw err;
    }

    const { data: matchedUser } = await supabase
        .from('users')
        .select('id, email')
        .eq('email', email)
        .maybeSingle();

    const inviteToken = randomUUID().replace(/-/g, '');
    const expiresAt = new Date(Date.now() + Math.max(1, expiresInDays) * 24 * 60 * 60 * 1000).toISOString();

    const { data, error } = await supabase
        .from('vendor_staff_invitations')
        .insert({
            vendor_id: vendor.id,
            email,
            role_key: roleKey,
            invited_user_id: matchedUser?.id || null,
            invited_by: user.sub,
            status: 'pending',
            invite_token: inviteToken,
            expires_at: expiresAt,
            updated_at: new Date().toISOString(),
        })
        .select('id, email, role_key, status, invited_user_id, invite_token, expires_at, created_at')
        .single();

    if (error) throw error;

    await logVendorMutation(user.sub, 'vendor.staff.invitation.create', data?.id || null, `Invited ${email} to role ${roleKey}`);

    return reply.code(201).send({ invitation: data });
};

const defaultStaffRoles = [
    { key: 'manager', permissions: ['orders.manage', 'menu.manage', 'reports.view'] },
    { key: 'cashier', permissions: ['orders.view', 'orders.update_status'] },
    { key: 'kitchen', permissions: ['orders.view', 'orders.update_status', 'inventory.view'] },
];

export const getVendorStaffRoles = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const vendor = await resolveVendor(user.sub);

    const { data, error } = await supabase
        .from('vendor_staff_roles')
        .select('role_key, permissions')
        .eq('vendor_id', vendor.id)
        .order('role_key', { ascending: true });

    if (error) throw error;

    const roles = (data || []).map((entry: any) => ({
        key: entry.role_key,
        permissions: Array.isArray(entry.permissions) ? entry.permissions : [],
    }));

    return reply.send({ roles: roles.length > 0 ? roles : defaultStaffRoles });
};

export const updateVendorStaffRoles = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const body = request.body as any;
    const vendor = await resolveVendor(user.sub);

    if (!Array.isArray(body?.roles) || body.roles.length === 0) {
        const err = new Error('roles must be a non-empty array') as any;
        err.statusCode = 400;
        throw err;
    }

    const rows = body.roles
        .map((role: any) => {
            const key = trimToNull(role?.key);
            if (!key) return null;
            const permissions = Array.isArray(role?.permissions)
                ? role.permissions
                    .map((entry: unknown) => trimToNull(entry))
                    .filter((entry: string | null): entry is string => entry !== null)
                : [];
            return {
                vendor_id: vendor.id,
                role_key: key,
                permissions,
                updated_at: new Date().toISOString(),
            };
        })
        .filter((role: any) => role !== null);

    if (rows.length === 0) {
        const err = new Error('roles must include valid key values') as any;
        err.statusCode = 400;
        throw err;
    }

    const { error } = await supabase
        .from('vendor_staff_roles')
        .upsert(rows, { onConflict: 'vendor_id,role_key' });

    if (error) throw error;
    await logVendorMutation(user.sub, 'vendor.staff.roles.update', vendor.id, `Upserted ${rows.length} role definitions`);
    return getVendorStaffRoles(request, reply);
};

export const getVendorReportsDownload = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const vendor = await resolveVendor(user.sub);

    const { data: rows, error } = await supabase
        .from('orders')
        .select('id, status, total_amount, created_at')
        .eq('vendor_id', vendor.id)
        .order('created_at', { ascending: false })
        .limit(50);
    if (error) throw error;

    const csv = ['order_id,status,total_amount,created_at', ...(rows || []).map((r: any) => `${r.id},${r.status},${amount(r.total_amount)},${r.created_at}`)].join('\n');
    return reply.send({ export: { format: 'csv', csv } });
};

export const getVendorReportsSales = async (request: FastifyRequest, reply: FastifyReply) => {
    return getVendorAnalyticsSales(request, reply);
};

export const getVendorReportsOrders = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const vendor = await resolveVendor(user.sub);

    const { data: orders, error } = await supabase
        .from('orders')
        .select('status')
        .eq('vendor_id', vendor.id);

    if (error) throw error;

    const statusCounts: Record<string, number> = {};
    for (const row of orders || []) {
        const status = ((row as any).status || 'unknown').toLowerCase();
        statusCounts[status] = (statusCounts[status] || 0) + 1;
    }

    return reply.send({ orders_report: statusCounts });
};

export const getVendorPreferencesLanguage = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const vendor = await resolveVendor(user.sub);

    const { data: settings } = await supabase
        .from('vendor_settings')
        .select('preferred_language')
        .eq('vendor_id', vendor.id)
        .maybeSingle();

    return reply.send({
        language: {
            current: settings?.preferred_language || 'English',
            options: ['English', 'Hindi'],
        },
    });
};

export const updateVendorPreferencesLanguage = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const body = request.body as any;
    const vendor = await resolveVendor(user.sub);

    const current = trimToNull(body?.current);
    if (!current) {
        const err = new Error('current language is required') as any;
        err.statusCode = 400;
        throw err;
    }

    const { error } = await supabase
        .from('vendor_settings')
        .upsert({
            vendor_id: vendor.id,
            preferred_language: current,
        }, { onConflict: 'vendor_id' });

    if (error) throw error;
    await logVendorMutation(user.sub, 'vendor.preferences.language.update', vendor.id, `Set language to ${current}`);
    return getVendorPreferencesLanguage(request, reply);
};

export const getVendorPreferencesTheme = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const vendor = await resolveVendor(user.sub);

    const { data: settings } = await supabase
        .from('vendor_settings')
        .select('theme_dark_mode, theme_high_contrast')
        .eq('vendor_id', vendor.id)
        .maybeSingle();

    return reply.send({
        theme: {
            dark_mode: settings?.theme_dark_mode === true,
            high_contrast: settings?.theme_high_contrast === true,
        },
    });
};

export const updateVendorPreferencesTheme = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const body = request.body as any;
    const vendor = await resolveVendor(user.sub);

    const patch: Record<string, unknown> = { vendor_id: vendor.id };
    if (typeof body?.dark_mode === 'boolean') patch.theme_dark_mode = body.dark_mode;
    if (typeof body?.high_contrast === 'boolean') patch.theme_high_contrast = body.high_contrast;

    if (Object.keys(patch).length === 1) {
        const err = new Error('At least one theme field must be provided') as any;
        err.statusCode = 400;
        throw err;
    }

    const { error } = await supabase
        .from('vendor_settings')
        .upsert(patch, { onConflict: 'vendor_id' });

    if (error) throw error;
    await logVendorMutation(user.sub, 'vendor.preferences.theme.update', vendor.id, 'Updated theme preferences');
    return getVendorPreferencesTheme(request, reply);
};

export const getVendorPreferencesApp = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const vendor = await resolveVendor(user.sub);

    const { data: settings } = await supabase
        .from('vendor_settings')
        .select('busy_mode_enabled, auto_accept_orders, preparation_time_avg, app_compact_cards, app_silent_alerts, app_notification_enabled, app_auto_print_receipts')
        .eq('vendor_id', vendor.id)
        .maybeSingle();

    return reply.send({
        app_settings: {
            compact_cards: settings?.app_compact_cards === true,
            silent_alerts: settings?.app_silent_alerts === true,
            notification_enabled: settings?.app_notification_enabled !== false,
            auto_print_receipts: settings?.app_auto_print_receipts === true,
            auto_accept_orders: settings?.auto_accept_orders === true,
            busy_mode_enabled: settings?.busy_mode_enabled === true,
            preparation_time_avg: Number(settings?.preparation_time_avg ?? 15),
        },
    });
};

export const updateVendorPreferencesApp = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const body = request.body as any;
    const vendor = await resolveVendor(user.sub);

    const patch: Record<string, unknown> = { vendor_id: vendor.id };
    if (typeof body?.compact_cards === 'boolean') patch.app_compact_cards = body.compact_cards;
    if (typeof body?.silent_alerts === 'boolean') patch.app_silent_alerts = body.silent_alerts;
    if (typeof body?.notification_enabled === 'boolean') patch.app_notification_enabled = body.notification_enabled;
    if (typeof body?.auto_print_receipts === 'boolean') patch.app_auto_print_receipts = body.auto_print_receipts;

    if (Object.keys(patch).length === 1) {
        const err = new Error('At least one app setting field must be provided') as any;
        err.statusCode = 400;
        throw err;
    }

    const { error } = await supabase
        .from('vendor_settings')
        .upsert(patch, { onConflict: 'vendor_id' });

    if (error) throw error;
    await logVendorMutation(user.sub, 'vendor.preferences.app.update', vendor.id, 'Updated app preference settings');
    return getVendorPreferencesApp(request, reply);
};
