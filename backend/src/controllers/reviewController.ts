import { FastifyRequest, FastifyReply } from 'fastify';
import { supabase } from '../services/supabase';

export const createReview = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const { order_id, rating, comment } = request.body as any;

    if (!order_id || !rating) {
        const err = new Error('Order ID and rating are required') as any;
        err.statusCode = 400;
        throw err;
    }

    // 1. Verify order exists, belongs to user, and is delivered
    const { data: order, error: orderError } = await supabase
        .from('orders')
        .select('vendor_id, status')
        .eq('id', order_id)
        .eq('user_id', user.sub)
        .single();

    if (orderError || !order) {
        const err = new Error('Order not found or not authorized') as any;
        err.statusCode = 404;
        throw err;
    }

    if (order.status !== 'delivered') {
        const err = new Error('You can only review delivered orders') as any;
        err.statusCode = 400;
        throw err;
    }

    // 2. Create the review
    const { data, error } = await supabase
        .from('reviews')
        .insert({
            order_id,
            user_id: user.sub,
            vendor_id: order.vendor_id,
            rating,
            comment
        })
        .select()
        .single();

    if (error) {
        if (error.code === '23505') {
            const err = new Error('You have already reviewed this order') as any;
            err.statusCode = 400;
            throw err;
        }
        throw error;
    }

    return reply.code(201).send(data);
};

export const getVendorReviews = async (request: FastifyRequest, reply: FastifyReply) => {
    const { vendorId } = request.params as any;

    const { data, error } = await supabase
        .from('reviews')
        .select('*, users(name)')
        .eq('vendor_id', vendorId)
        .order('created_at', { ascending: false });

    if (error) throw error;
    return reply.send(data);
};
