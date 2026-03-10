import { FastifyRequest, FastifyReply } from 'fastify';
import { supabase } from '../services/supabase';

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
        item_id: item.id,
        quantity: item.quantity,
        unit_price: item.price
    }));

    const { error: itemsError } = await supabase
        .from('order_items')
        .insert(orderItems);

    if (itemsError) throw itemsError;

    return reply.code(201).send(order);
};

export const getMyOrders = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;

    const { data, error } = await supabase
        .from('orders')
        .select('*, vendors(name), order_items(*, menu_items(name))')
        .eq('user_id', user.sub)
        .order('created_at', { ascending: false });

    if (error) throw error;
    return reply.send(data);
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
    return reply.send(data);
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
    return reply.send(data);
};
