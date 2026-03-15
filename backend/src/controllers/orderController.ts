import { FastifyRequest, FastifyReply } from 'fastify';
import { supabase } from '../services/supabase';

type EtaConfidence = 'low' | 'medium' | 'high';
type SlaRisk = 'low' | 'medium' | 'high';

const buildEtaTrust = (status: string | null | undefined, createdAt: string) => {
    const statusValue = (status || 'pending').toLowerCase();
    const created = new Date(createdAt).getTime();
    const ageMinutes = Math.max(0, Math.floor((Date.now() - created) / 60000));

    let minMinutes = 14;
    let maxMinutes = 24;
    let confidence: EtaConfidence = 'high';

    if (statusValue === 'accepted') {
        minMinutes = 10;
        maxMinutes = 18;
        confidence = 'high';
    } else if (statusValue === 'preparing') {
        minMinutes = 6;
        maxMinutes = 14;
        confidence = 'medium';
    } else if (statusValue === 'ready') {
        minMinutes = 2;
        maxMinutes = 6;
        confidence = 'high';
    } else if (statusValue === 'completed') {
        minMinutes = 0;
        maxMinutes = 0;
        confidence = 'high';
    } else if (statusValue === 'cancelled') {
        minMinutes = 0;
        maxMinutes = 0;
        confidence = 'low';
    }

    const adjustedMin = Math.max(0, minMinutes - Math.min(8, ageMinutes));
    const adjustedMax = Math.max(adjustedMin, maxMinutes - Math.min(12, ageMinutes));

    return {
        min_minutes: adjustedMin,
        max_minutes: adjustedMax,
        confidence,
        updated_at: new Date().toISOString(),
        note: 'ETA range is a rolling estimate based on queue status and order age.',
    };
};

const attachEtaTrust = <T extends { status?: string; created_at?: string }>(order: T) => ({
    ...order,
    eta: buildEtaTrust(order.status, order.created_at || new Date().toISOString()),
});

const buildVendorPacing = (order: any) => {
    const statusValue = (order?.status || 'accepted').toLowerCase();
    const created = new Date(order?.created_at || new Date().toISOString()).getTime();
    const elapsedMinutes = Math.max(0, Math.floor((Date.now() - created) / 60000));
    const itemCount = Array.isArray(order?.order_items) ? order.order_items.length : 0;
    const totalAmount = Number(order?.total_amount) || 0;

    const recommendedPrepMinutes = Math.min(24, Math.max(8, 8 + (itemCount * 2) + (totalAmount >= 300 ? 2 : 0)));
    const targetPrepMinutes = statusValue === 'ready' || statusValue === 'completed'
        ? Math.max(2, Math.floor(recommendedPrepMinutes / 2))
        : recommendedPrepMinutes;

    let slaRisk: SlaRisk = 'low';
    let paceLabel = 'on_track';

    if (statusValue === 'cancelled') {
        slaRisk = 'high';
        paceLabel = 'exception';
    } else if (statusValue === 'completed' || statusValue === 'ready') {
        slaRisk = 'low';
        paceLabel = 'settled';
    } else if (elapsedMinutes >= targetPrepMinutes + 4) {
        slaRisk = 'high';
        paceLabel = 'urgent';
    } else if (elapsedMinutes >= targetPrepMinutes) {
        slaRisk = 'medium';
        paceLabel = 'watch';
    }

    return {
        elapsed_minutes: elapsedMinutes,
        target_prep_minutes: targetPrepMinutes,
        recommended_prep_minutes: recommendedPrepMinutes,
        sla_risk: slaRisk,
        pace_label: paceLabel,
        note: 'Pacing score blends elapsed queue time, order size, and current status.',
    };
};

const attachVendorPacing = <T extends { status?: string; created_at?: string }>(order: T) => ({
    ...attachEtaTrust(order),
    pacing: buildVendorPacing(order),
});

export const createOrder = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const { vendor_id, items, total_amount } = request.body as any;

    const { data: order, error: orderError } = await supabase
        .from('orders')
        .insert({
            user_id: user.sub,
            vendor_id,
            total_amount,
            status: 'pending'
        })
        .select()
        .single();

    if (orderError) throw orderError;

    const orderItems = items.map((item: any) => ({
        order_id: order.id,
        item_id: item.id || item.menu_item_id,
        quantity: item.quantity,
        unit_price: item.price || item.unit_price
    }));

    const { error: itemsError } = await supabase
        .from('order_items')
        .insert(orderItems);

    if (itemsError) throw itemsError;

    return reply.code(201).send(attachEtaTrust(order));
};

export const getMyOrders = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;

    const { data, error } = await supabase
        .from('orders')
        .select('*, vendors(name), order_items(*, menu_items(name))')
        .eq('user_id', user.sub)
        .order('created_at', { ascending: false });

    if (error) throw error;
    return reply.send((data || []).map((order: any) => attachVendorPacing(order)));
};

export const updateOrderStatus = async (request: FastifyRequest, reply: FastifyReply) => {
    const { id } = request.params as any;
    const { status } = request.body as any;

    const { data, error } = await supabase
        .from('orders')
        .update({ status, updated_at: new Date().toISOString() })
        .eq('id', id)
        .select()
        .single();

    if (error) throw error;
    return reply.send(attachEtaTrust(data));
};

export const getVendorOrders = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;

    // 1. Find the vendor ID for this owner
    const { data: vendor, error: vendorError } = await supabase
        .from('vendors')
        .select('id')
        .eq('owner_id', user.sub)
        .single();

    if (vendorError || !vendor) {
        const err = new Error('Vendor not found') as any;
        err.statusCode = 404;
        throw err;
    }

    // 2. Get orders for this vendor
    const { data, error } = await supabase
        .from('orders')
        .select('*, users(name, email), order_items(*, menu_items(name))')
        .eq('vendor_id', vendor.id)
        .order('created_at', { ascending: false });

    if (error) throw error;
    return reply.send((data || []).map((order: any) => attachEtaTrust(order)));
};
