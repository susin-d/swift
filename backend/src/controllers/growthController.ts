import { FastifyReply, FastifyRequest } from 'fastify';
import { supabase } from '../services/supabase';

const userFromRequest = (request: FastifyRequest) => request.user as { sub: string; role: string } | undefined;

const ensureUser = (request: FastifyRequest, reply: FastifyReply) => {
    const user = userFromRequest(request);
    if (!user?.sub) {
        reply.code(401).send({ error: 'Unauthorized', message: 'Authentication required' });
        return null;
    }
    return user;
};

const safeJson = (value: unknown) => {
    if (value && typeof value === 'object') return value;
    return {};
};

const getTierForPoints = (points: number) => (
    points >= 1500 ? 'platinum' : points >= 800 ? 'gold' : points >= 300 ? 'silver' : 'bronze'
);

export const getSpendingAnalytics = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = ensureUser(request, reply);
    if (!user) return;

    const { data, error } = await supabase
        .from('orders')
        .select('total_amount, discount_amount, created_at, vendors(name, category)')
        .eq('user_id', user.sub)
        .order('created_at', { ascending: false })
        .limit(200);

    if (error) throw error;

    const rows = data || [];
    const totalSpent = rows.reduce((acc, row: any) => acc + Number(row.total_amount || 0), 0);
    const totalSaved = rows.reduce((acc, row: any) => acc + Number(row.discount_amount || 0), 0);

    const byMonth = new Map<string, number>();
    const byWeek = new Map<string, number>();
    const byCategory = new Map<string, number>();
    for (const row of rows as any[]) {
        const amount = Number(row.total_amount || 0);
        const timestamp = new Date(row.created_at || new Date().toISOString());
        const monthKey = `${timestamp.getUTCFullYear()}-${String(timestamp.getUTCMonth() + 1).padStart(2, '0')}`;
        const firstJan = new Date(Date.UTC(timestamp.getUTCFullYear(), 0, 1));
        const days = Math.floor((timestamp.getTime() - firstJan.getTime()) / 86400000);
        const week = Math.ceil((days + firstJan.getUTCDay() + 1) / 7);
        const weekKey = `${timestamp.getUTCFullYear()}-W${String(week).padStart(2, '0')}`;
        const category = String((row as any)?.vendors?.category || 'uncategorized');

        byMonth.set(monthKey, Number((byMonth.get(monthKey) || 0) + amount));
        byWeek.set(weekKey, Number((byWeek.get(weekKey) || 0) + amount));
        byCategory.set(category, Number((byCategory.get(category) || 0) + amount));
    }

    return reply.send({
        summary: {
            total_spent: Number(totalSpent.toFixed(2)),
            total_saved: Number(totalSaved.toFixed(2)),
            total_orders: rows.length,
        },
        monthly: Array.from(byMonth.entries()).map(([month, amount]) => ({ month, amount: Number(amount.toFixed(2)) })),
        weekly: Array.from(byWeek.entries()).map(([week, amount]) => ({ week, amount: Number(amount.toFixed(2)) })),
        categories: Array.from(byCategory.entries())
            .map(([category, amount]) => ({ category, amount: Number(amount.toFixed(2)) }))
            .sort((a, b) => b.amount - a.amount),
    });
};

export const getVendorSpendingAnalytics = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = ensureUser(request, reply);
    if (!user) return;

    const { data, error } = await supabase
        .from('orders')
        .select('vendor_id, total_amount, vendors(name)')
        .eq('user_id', user.sub)
        .order('created_at', { ascending: false })
        .limit(200);

    if (error) throw error;

    const grouped = new Map<string, { vendor_id: string; vendor_name: string; amount: number; orders: number }>();
    for (const row of (data || []) as any[]) {
        const vendorId = String(row.vendor_id || '');
        if (!grouped.has(vendorId)) {
            grouped.set(vendorId, {
                vendor_id: vendorId,
                vendor_name: String(row.vendors?.name || 'Unknown vendor'),
                amount: 0,
                orders: 0,
            });
        }
        const entry = grouped.get(vendorId)!;
        entry.amount += Number(row.total_amount || 0);
        entry.orders += 1;
    }

    return reply.send({
        vendors: Array.from(grouped.values())
            .map((entry) => ({ ...entry, amount: Number(entry.amount.toFixed(2)) }))
            .sort((a, b) => b.amount - a.amount),
    });
};

export const generateReferralCode = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = ensureUser(request, reply);
    if (!user) return;

    const { data: existing, error: existingError } = await supabase
        .from('referral_codes')
        .select('*')
        .eq('user_id', user.sub)
        .eq('is_active', true)
        .maybeSingle();

    if (existingError) throw existingError;
    if (existing) return reply.send({ referral: existing });

    const code = `SWIFT${Math.random().toString(36).slice(2, 8).toUpperCase()}`;
    const { data, error } = await supabase
        .from('referral_codes')
        .insert({
            user_id: user.sub,
            code,
            is_active: true,
            metadata: {},
        })
        .select('*')
        .single();
    if (error) throw error;

    return reply.code(201).send({ referral: data });
};

export const getReferralByCode = async (
    request: FastifyRequest<{ Params: { code: string } }>,
    reply: FastifyReply,
) => {
    const code = String(request.params.code || '').trim().toUpperCase();
    if (!code) return reply.code(400).send({ error: 'ValidationError', message: 'Referral code is required' });

    const { data, error } = await supabase
        .from('referral_codes')
        .select('*')
        .eq('code', code)
        .eq('is_active', true)
        .maybeSingle();

    if (error) throw error;
    if (!data) return reply.code(404).send({ error: 'NotFound', message: 'Referral code not found' });
    return reply.send({ referral: data });
};

export const redeemReferralCode = async (
    request: FastifyRequest<{ Body: { code?: string } }>,
    reply: FastifyReply,
) => {
    const user = ensureUser(request, reply);
    if (!user) return;

    const code = String(request.body?.code || '').trim().toUpperCase();
    if (!code) return reply.code(400).send({ error: 'ValidationError', message: 'Referral code is required' });

    const { data: referral, error: referralError } = await supabase
        .from('referral_codes')
        .select('*')
        .eq('code', code)
        .eq('is_active', true)
        .maybeSingle();
    if (referralError) throw referralError;
    if (!referral) return reply.code(404).send({ error: 'NotFound', message: 'Referral code not found' });
    if (referral.user_id === user.sub) return reply.code(400).send({ error: 'ValidationError', message: 'Cannot redeem your own code' });

    const { data: existingRedemption, error: existingRedemptionError } = await supabase
        .from('referral_redemptions')
        .select('id')
        .eq('referee_user_id', user.sub)
        .maybeSingle();
    if (existingRedemptionError) throw existingRedemptionError;
    if (existingRedemption) {
        return reply.code(409).send({ error: 'Conflict', message: 'Referral already redeemed for this account' });
    }

    const { data: completedOrder, error: completedOrderError } = await supabase
        .from('orders')
        .select('id')
        .eq('user_id', user.sub)
        .eq('status', 'completed')
        .limit(1)
        .maybeSingle();
    if (completedOrderError) throw completedOrderError;
    if (completedOrder) {
        return reply.code(400).send({ error: 'ValidationError', message: 'Referral can only be redeemed before first completed order' });
    }

    const { data, error } = await supabase
        .from('referral_redemptions')
        .insert({
            referral_code_id: referral.id,
            referee_user_id: user.sub,
            metadata: {},
        })
        .select('*')
        .single();
    if (error) throw error;

    return reply.code(201).send({ redemption: data });
};

export const getLoyaltyTier = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = ensureUser(request, reply);
    if (!user) return;

    const { data: existing, error: existingError } = await supabase
        .from('loyalty_accounts')
        .select('*')
        .eq('user_id', user.sub)
        .maybeSingle();
    if (existingError) throw existingError;

    if (existing) return reply.send({ loyalty: existing });

    const { data, error } = await supabase
        .from('loyalty_accounts')
        .insert({
            user_id: user.sub,
            points: 0,
            tier: 'bronze',
            metadata: {},
        })
        .select('*')
        .single();
    if (error) throw error;
    return reply.send({ loyalty: data });
};

export const addLoyaltyPoints = async (
    request: FastifyRequest<{ Body: { points?: number; reason?: string; action?: 'earn' | 'redeem' } }>,
    reply: FastifyReply,
) => {
    const user = ensureUser(request, reply);
    if (!user) return;
    if (user.role !== 'admin') {
        return reply.code(403).send({
            error: 'Forbidden',
            message: 'Loyalty point mutations require admin authorization',
        });
    }

    const targetUserId = String((request.body as any)?.userId || '').trim();
    if (!targetUserId) {
        return reply.code(400).send({
            error: 'ValidationError',
            message: 'userId is required for loyalty point mutations',
        });
    }

    const points = Math.floor(Number(request.body?.points || 0));
    const action = request.body?.action || 'earn';
    if (!Number.isFinite(points) || points <= 0) {
        return reply.code(400).send({ error: 'ValidationError', message: 'points must be greater than 0' });
    }
    if (!['earn', 'redeem'].includes(action)) {
        return reply.code(400).send({ error: 'ValidationError', message: 'action must be earn or redeem' });
    }

    const { data: current, error: currentError } = await supabase
        .from('loyalty_accounts')
        .select('*')
        .eq('user_id', targetUserId)
        .maybeSingle();
    if (currentError) throw currentError;

    const currentPoints = Number(current?.points || 0);
    const nextPoints = action === 'redeem'
        ? currentPoints - points
        : currentPoints + points;
    if (nextPoints < 0) {
        return reply.code(400).send({ error: 'ValidationError', message: 'Insufficient loyalty points' });
    }
    const nextTier = getTierForPoints(nextPoints);

    const { data, error } = await supabase
        .from('loyalty_accounts')
        .upsert({
            user_id: targetUserId,
            points: nextPoints,
            tier: nextTier,
            metadata: safeJson(current?.metadata),
        }, { onConflict: 'user_id' })
        .select('*')
        .single();
    if (error) throw error;

    await supabase.from('loyalty_events').insert({
        user_id: targetUserId,
        points_delta: action === 'redeem' ? -points : points,
        reason: request.body?.reason || 'manual',
        metadata: { action },
    });

    return reply.send({ loyalty: data });
};

export const getSubscriptions = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = ensureUser(request, reply);
    if (!user) return;
    const { data, error } = await supabase
        .from('subscriptions')
        .select('*')
        .eq('user_id', user.sub)
        .order('created_at', { ascending: false });
    if (error) throw error;
    return reply.send({ subscriptions: data || [] });
};

export const createSubscription = async (
    request: FastifyRequest<{ Body: { plan?: string; metadata?: Record<string, unknown> } }>,
    reply: FastifyReply,
) => {
    const user = ensureUser(request, reply);
    if (!user) return;
    if (user.role !== 'admin') {
        return reply.code(403).send({
            error: 'Forbidden',
            message: 'Subscription activation requires verified payment processing',
        });
    }

    const targetUserId = String((request.body as any)?.userId || '').trim();
    if (!targetUserId) {
        return reply.code(400).send({
            error: 'ValidationError',
            message: 'userId is required for subscription activation',
        });
    }

    const plan = String(request.body?.plan || '').trim();
    if (!plan) return reply.code(400).send({ error: 'ValidationError', message: 'plan is required' });
    const { data: activeSub, error: activeSubError } = await supabase
        .from('subscriptions')
        .select('id')
        .eq('user_id', targetUserId)
        .eq('status', 'active')
        .maybeSingle();
    if (activeSubError) throw activeSubError;
    if (activeSub) return reply.code(409).send({ error: 'Conflict', message: 'Active subscription already exists' });

    const now = new Date();
    const renewalDate = new Date(now);
    renewalDate.setDate(renewalDate.getDate() + 30);
    const { data, error } = await supabase
        .from('subscriptions')
        .insert({
            user_id: targetUserId,
            plan,
            status: 'active',
            metadata: {
                ...safeJson(request.body?.metadata),
                renewal_date: renewalDate.toISOString(),
                activated_by: user.sub,
            },
        })
        .select('*')
        .single();
    if (error) throw error;
    return reply.code(201).send({ subscription: data });
};

export const cancelSubscription = async (
    request: FastifyRequest<{ Params: { id: string } }>,
    reply: FastifyReply,
) => {
    const user = ensureUser(request, reply);
    if (!user) return;
    const subscriptionId = String(request.params.id || '').trim();
    if (!subscriptionId) return reply.code(400).send({ error: 'ValidationError', message: 'subscription id is required' });

    const { data, error } = await supabase
        .from('subscriptions')
        .update({ status: 'cancelled', updated_at: new Date().toISOString() })
        .eq('id', subscriptionId)
        .eq('user_id', user.sub)
        .select('*')
        .maybeSingle();
    if (error) throw error;
    if (!data) return reply.code(404).send({ error: 'NotFound', message: 'Subscription not found' });

    return reply.send({ subscription: data });
};

export const renewSubscription = async (
    request: FastifyRequest<{ Params: { id: string } }>,
    reply: FastifyReply,
) => {
    const user = ensureUser(request, reply);
    if (!user) return;
    if (user.role !== 'admin') {
        return reply.code(403).send({
            error: 'Forbidden',
            message: 'Subscription renewal requires verified payment processing',
        });
    }
    const subscriptionId = String(request.params.id || '').trim();
    if (!subscriptionId) return reply.code(400).send({ error: 'ValidationError', message: 'subscription id is required' });

    const { data: current, error: currentError } = await supabase
        .from('subscriptions')
        .select('*')
        .eq('id', subscriptionId)
        .maybeSingle();
    if (currentError) throw currentError;
    if (!current) return reply.code(404).send({ error: 'NotFound', message: 'Subscription not found' });

    const renewalDate = new Date();
    renewalDate.setDate(renewalDate.getDate() + 30);
    const nextMetadata = {
        ...safeJson((current as any).metadata),
        renewal_date: renewalDate.toISOString(),
    };
    const { data, error } = await supabase
        .from('subscriptions')
        .update({
            status: 'active',
            metadata: nextMetadata,
            updated_at: new Date().toISOString(),
        })
        .eq('id', subscriptionId)
        .eq('user_id', user.sub)
        .select('*')
        .single();
    if (error) throw error;
    return reply.send({ subscription: data });
};

export const getSubscriptionEntitlements = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = ensureUser(request, reply);
    if (!user) return;

    const { data: activeSub, error } = await supabase
        .from('subscriptions')
        .select('*')
        .eq('user_id', user.sub)
        .eq('status', 'active')
        .maybeSingle();
    if (error) throw error;

    if (!activeSub) {
        return reply.send({
            entitlements: {
                delivery_fee_waiver: false,
                priority_support: false,
                exclusive_promos: false,
            },
            subscription: null,
        });
    }

    const plan = String((activeSub as any).plan || '');
    return reply.send({
        entitlements: {
            delivery_fee_waiver: plan === 'plus' || plan === 'pro',
            priority_support: plan === 'pro',
            exclusive_promos: plan === 'plus' || plan === 'pro',
        },
        subscription: activeSub,
    });
};

export const watchVendor = async (
    request: FastifyRequest<{ Params: { id: string } }>,
    reply: FastifyReply,
) => {
    const user = ensureUser(request, reply);
    if (!user) return;
    const vendorId = String(request.params.id || '').trim();
    if (!vendorId) return reply.code(400).send({ error: 'ValidationError', message: 'vendor id is required' });

    const { data, error } = await supabase
        .from('vendor_watches')
        .upsert({ user_id: user.sub, vendor_id: vendorId }, { onConflict: 'user_id,vendor_id' })
        .select('*')
        .single();
    if (error) throw error;
    return reply.send({ watch: data });
};

export const unwatchVendor = async (
    request: FastifyRequest<{ Params: { id: string } }>,
    reply: FastifyReply,
) => {
    const user = ensureUser(request, reply);
    if (!user) return;
    const vendorId = String(request.params.id || '').trim();
    if (!vendorId) return reply.code(400).send({ error: 'ValidationError', message: 'vendor id is required' });

    const { error } = await supabase
        .from('vendor_watches')
        .delete()
        .eq('user_id', user.sub)
        .eq('vendor_id', vendorId);
    if (error) throw error;
    return reply.send({ success: true });
};

export const createGroupOrder = async (
    request: FastifyRequest<{ Body: { orderId?: string; participantIds?: string[] } }>,
    reply: FastifyReply,
) => {
    const user = ensureUser(request, reply);
    if (!user) return;

    const orderId = String(request.body?.orderId || '').trim();
    if (!orderId) return reply.code(400).send({ error: 'ValidationError', message: 'orderId is required' });

    const participantIds = Array.isArray(request.body?.participantIds)
        ? request.body?.participantIds.filter((id) => typeof id === 'string' && id.trim().length > 0)
        : [];

    const { data: groupOrder, error: groupOrderError } = await supabase
        .from('group_orders')
        .insert({
            order_id: orderId,
            host_user_id: user.sub,
            status: 'active',
            metadata: {},
        })
        .select('*')
        .single();
    if (groupOrderError) throw groupOrderError;

    const members = Array.from(new Set([user.sub, ...participantIds])).map((participantId) => ({
        group_order_id: groupOrder.id,
        user_id: participantId,
        contribution_amount: 0,
    }));
    if (members.length > 0) {
        const { error: membersError } = await supabase.from('group_order_members').insert(members);
        if (membersError) throw membersError;
    }

    return reply.code(201).send({ group_order: groupOrder });
};

export const splitOrderAmount = async (
    request: FastifyRequest<{ Params: { id: string }; Body: { splits?: Array<{ userId: string; amount: number }> } }>,
    reply: FastifyReply,
) => {
    const user = ensureUser(request, reply);
    if (!user) return;

    const orderId = String(request.params.id || '').trim();
    const splits = Array.isArray(request.body?.splits) ? request.body!.splits : [];
    if (!orderId || splits.length === 0) {
        return reply.code(400).send({ error: 'ValidationError', message: 'order id and splits are required' });
    }

    const { data: groupOrder, error: groupOrderError } = await supabase
        .from('group_orders')
        .select('*')
        .eq('order_id', orderId)
        .eq('host_user_id', user.sub)
        .maybeSingle();
    if (groupOrderError) throw groupOrderError;
    if (!groupOrder) return reply.code(404).send({ error: 'NotFound', message: 'Group order not found' });

    const { data: order, error: orderError } = await supabase
        .from('orders')
        .select('total_amount')
        .eq('id', orderId)
        .maybeSingle();
    if (orderError) throw orderError;
    const orderTotal = Number((order as any)?.total_amount || 0);
    const splitTotal = Number(splits.reduce((acc, split) => acc + Number(split.amount || 0), 0).toFixed(2));
    if (orderTotal > 0 && Math.abs(splitTotal - orderTotal) > 0.01) {
        return reply.code(400).send({
            error: 'ValidationError',
            message: `Split total (${splitTotal}) must match order total (${orderTotal})`,
        });
    }

    for (const split of splits) {
        await supabase
            .from('group_order_members')
            .update({ contribution_amount: Number(split.amount || 0) })
            .eq('group_order_id', groupOrder.id)
            .eq('user_id', split.userId);
    }

    return reply.send({ success: true });
};

export const getGroupOrder = async (
    request: FastifyRequest<{ Params: { id: string } }>,
    reply: FastifyReply,
) => {
    const user = ensureUser(request, reply);
    if (!user) return;

    const orderId = String(request.params.id || '').trim();
    if (!orderId) return reply.code(400).send({ error: 'ValidationError', message: 'order id is required' });

    const { data: groupOrder, error: groupOrderError } = await supabase
        .from('group_orders')
        .select('*')
        .eq('order_id', orderId)
        .maybeSingle();
    if (groupOrderError) throw groupOrderError;
    if (!groupOrder) return reply.code(404).send({ error: 'NotFound', message: 'Group order not found' });

    const { data: members, error: membersError } = await supabase
        .from('group_order_members')
        .select('*')
        .eq('group_order_id', (groupOrder as any).id)
        .order('created_at', { ascending: true });
    if (membersError) throw membersError;

    const isParticipant = (members || []).some((member: any) => member.user_id === user.sub);
    if ((groupOrder as any).host_user_id !== user.sub && !isParticipant && user.role !== 'admin') {
        return reply.code(403).send({ error: 'Forbidden', message: 'Not a participant in this group order' });
    }

    return reply.send({ group_order: groupOrder, members: members || [] });
};

export const joinGroupOrder = async (
    request: FastifyRequest<{ Params: { id: string } }>,
    reply: FastifyReply,
) => {
    const user = ensureUser(request, reply);
    if (!user) return;
    const orderId = String(request.params.id || '').trim();
    if (!orderId) return reply.code(400).send({ error: 'ValidationError', message: 'order id is required' });

    const { data: groupOrder, error: groupOrderError } = await supabase
        .from('group_orders')
        .select('*')
        .eq('order_id', orderId)
        .maybeSingle();
    if (groupOrderError) throw groupOrderError;
    if (!groupOrder) return reply.code(404).send({ error: 'NotFound', message: 'Group order not found' });
    if ((groupOrder as any).status !== 'active') {
        return reply.code(400).send({ error: 'ValidationError', message: 'Group order is not active' });
    }

    const { data, error } = await supabase
        .from('group_order_members')
        .upsert({
            group_order_id: (groupOrder as any).id,
            user_id: user.sub,
            contribution_amount: 0,
        }, { onConflict: 'group_order_id,user_id' })
        .select('*')
        .single();
    if (error) throw error;

    return reply.send({ member: data });
};

export const leaveGroupOrder = async (
    request: FastifyRequest<{ Params: { id: string } }>,
    reply: FastifyReply,
) => {
    const user = ensureUser(request, reply);
    if (!user) return;
    const orderId = String(request.params.id || '').trim();
    if (!orderId) return reply.code(400).send({ error: 'ValidationError', message: 'order id is required' });

    const { data: groupOrder, error: groupOrderError } = await supabase
        .from('group_orders')
        .select('*')
        .eq('order_id', orderId)
        .maybeSingle();
    if (groupOrderError) throw groupOrderError;
    if (!groupOrder) return reply.code(404).send({ error: 'NotFound', message: 'Group order not found' });
    if ((groupOrder as any).host_user_id === user.sub) {
        return reply.code(400).send({ error: 'ValidationError', message: 'Host cannot leave. Close group order instead.' });
    }

    const { error } = await supabase
        .from('group_order_members')
        .delete()
        .eq('group_order_id', (groupOrder as any).id)
        .eq('user_id', user.sub);
    if (error) throw error;
    return reply.send({ success: true });
};

export const closeGroupOrder = async (
    request: FastifyRequest<{ Params: { id: string } }>,
    reply: FastifyReply,
) => {
    const user = ensureUser(request, reply);
    if (!user) return;
    const orderId = String(request.params.id || '').trim();
    if (!orderId) return reply.code(400).send({ error: 'ValidationError', message: 'order id is required' });

    const { data, error } = await supabase
        .from('group_orders')
        .update({ status: 'completed', updated_at: new Date().toISOString() })
        .eq('order_id', orderId)
        .eq('host_user_id', user.sub)
        .select('*')
        .maybeSingle();
    if (error) throw error;
    if (!data) return reply.code(404).send({ error: 'NotFound', message: 'Group order not found' });
    return reply.send({ group_order: data });
};

export const requestRefund = async (
    request: FastifyRequest<{ Params: { id: string }; Body: { reason?: string; amount?: number } }>,
    reply: FastifyReply,
) => {
    const user = ensureUser(request, reply);
    if (!user) return;

    const orderId = String(request.params.id || '').trim();
    const reason = String(request.body?.reason || '').trim();
    if (!orderId || !reason) {
        return reply.code(400).send({ error: 'ValidationError', message: 'order id and reason are required' });
    }

    const { data: order, error: orderError } = await supabase
        .from('orders')
        .select('id, user_id, total_amount')
        .eq('id', orderId)
        .maybeSingle();
    if (orderError) throw orderError;
    if (!order) return reply.code(404).send({ error: 'NotFound', message: 'Order not found' });
    if ((order as any).user_id !== user.sub) {
        return reply.code(403).send({ error: 'Forbidden', message: 'You cannot request refund for this order' });
    }

    const { data, error } = await supabase
        .from('refund_requests')
        .insert({
            order_id: orderId,
            user_id: user.sub,
            reason,
            amount: Number(request.body?.amount || (order as any).total_amount || 0),
            status: 'pending',
            metadata: {},
        })
        .select('*')
        .single();
    if (error) throw error;

    return reply.code(201).send({ refund: data });
};

export const getMyRefunds = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = ensureUser(request, reply);
    if (!user) return;

    const { data, error } = await supabase
        .from('refund_requests')
        .select('*')
        .eq('user_id', user.sub)
        .order('created_at', { ascending: false });
    if (error) throw error;

    return reply.send({ refunds: data || [] });
};

export const listRefundsAdmin = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = ensureUser(request, reply);
    if (!user) return;
    if (user.role !== 'admin') {
        return reply.code(403).send({ error: 'Forbidden', message: 'Admin access required' });
    }

    const { data, error } = await supabase
        .from('refund_requests')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(300);
    if (error) throw error;
    return reply.send({ refunds: data || [] });
};

export const updateRefundStatusAdmin = async (
    request: FastifyRequest<{ Params: { id: string }; Body: { status?: 'approved' | 'rejected' | 'processed'; note?: string } }>,
    reply: FastifyReply,
) => {
    const user = ensureUser(request, reply);
    if (!user) return;
    if (user.role !== 'admin') {
        return reply.code(403).send({ error: 'Forbidden', message: 'Admin access required' });
    }

    const refundId = String(request.params.id || '').trim();
    const status = request.body?.status;
    if (!refundId || !status) {
        return reply.code(400).send({ error: 'ValidationError', message: 'refund id and status are required' });
    }
    if (!['approved', 'rejected', 'processed'].includes(status)) {
        return reply.code(400).send({ error: 'ValidationError', message: 'invalid refund status' });
    }

    const { data: current, error: currentError } = await supabase
        .from('refund_requests')
        .select('*')
        .eq('id', refundId)
        .maybeSingle();
    if (currentError) throw currentError;
    if (!current) return reply.code(404).send({ error: 'NotFound', message: 'Refund request not found' });

    const metadata = {
        ...safeJson((current as any).metadata),
        admin_note: request.body?.note || null,
        updated_by: user.sub,
    };
    const { data, error } = await supabase
        .from('refund_requests')
        .update({ status, metadata, updated_at: new Date().toISOString() })
        .eq('id', refundId)
        .select('*')
        .single();
    if (error) throw error;

    return reply.send({ refund: data });
};
