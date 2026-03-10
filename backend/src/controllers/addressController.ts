import { FastifyRequest, FastifyReply } from 'fastify';
import { supabase } from '../services/supabase';

export const getAddresses = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;

    const { data, error } = await supabase
        .from('user_addresses')
        .select('*')
        .eq('user_id', user.sub)
        .order('is_default', { ascending: false })
        .order('created_at', { ascending: false });

    if (error) throw error;
    return reply.send(data);
};

export const addAddress = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const { label, address_line, is_default } = request.body as any;

    if (!label || !address_line) {
        const err = new Error('Label and address_line are required') as any;
        err.statusCode = 400;
        throw err;
    }

    const { data, error } = await supabase
        .from('user_addresses')
        .insert({
            user_id: user.sub,
            label,
            address_line,
            is_default: !!is_default
        })
        .select()
        .single();

    if (error) throw error;
    return reply.code(201).send(data);
};

export const deleteAddress = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const { id } = request.params as any;

    const { error } = await supabase
        .from('user_addresses')
        .delete()
        .eq('id', id)
        .eq('user_id', user.sub);

    if (error) throw error;
    return reply.code(204).send();
};

export const setDefaultAddress = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const { id } = request.params as any;

    const { data, error } = await supabase
        .from('user_addresses')
        .update({ is_default: true })
        .eq('id', id)
        .eq('user_id', user.sub)
        .select()
        .single();

    if (error) throw error;
    return reply.send(data);
};
