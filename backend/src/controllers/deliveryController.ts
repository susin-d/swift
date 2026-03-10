import { FastifyRequest, FastifyReply } from 'fastify';
import { supabase } from '../services/supabase';

export const updateLocation = async (request: FastifyRequest, reply: FastifyReply) => {
    const { order_id, lat, lng } = request.body as any;

    if (!order_id || lat === undefined || lng === undefined) {
        const err = new Error('Order ID, lat, and lng are required') as any;
        err.statusCode = 400;
        throw err;
    }

    const { data, error } = await supabase
        .from('order_delivery_locations')
        .upsert({
            order_id,
            lat,
            lng,
            updated_at: new Date().toISOString()
        })
        .select()
        .single();

    if (error) throw error;
    return reply.send({ message: 'Location updated', data });
};

export const getLocation = async (request: FastifyRequest, reply: FastifyReply) => {
    const { orderId } = request.params as any;

    const { data, error } = await supabase
        .from('order_delivery_locations')
        .select('*')
        .eq('order_id', orderId)
        .single();

    if (error) {
        if (error.code === 'PGRST116') {
            return reply.send({ message: 'No location data available yet', data: null });
        }
        throw error;
    }

    return reply.send(data);
};
