import { FastifyRequest, FastifyReply } from 'fastify';
import { supabase } from '../services/supabase';

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
        .select('*')
        .order('name', { ascending: true });

    if (error) throw error;
    return reply.send(data);
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
