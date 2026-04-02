import { FastifyRequest, FastifyReply } from 'fastify';
import { supabase } from '../services/supabase';
import crypto from 'crypto';

export const requestAccountDeletion = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const token = crypto.randomBytes(32).toString('hex');
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString();
    // Delete any existing pending request
    await supabase.from('deletion_requests').delete().eq('user_id', user.sub).is('executed_at', null);
    const { error } = await supabase
        .from('deletion_requests')
        .insert({ user_id: user.sub, token, expires_at: expiresAt });
    if (error) throw error;
    return reply.send({ message: 'Account deletion scheduled. You have 7 days to cancel.', expires_at: expiresAt });
};

export const cancelAccountDeletion = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const { error } = await supabase
        .from('deletion_requests')
        .delete()
        .eq('user_id', user.sub)
        .is('executed_at', null);
    if (error) throw error;
    return reply.send({ message: 'Account deletion cancelled.' });
};

export const confirmAccountDeletion = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const { token } = request.body as { token: string };
    if (!token) {
        return reply.code(400).send({ error: 'MissingToken', message: 'Token is required' });
    }
    const { data: req, error } = await supabase
        .from('deletion_requests')
        .select('*')
        .eq('user_id', user.sub)
        .eq('token', token)
        .is('executed_at', null)
        .single();
    if (error || !req) {
        return reply.code(404).send({ error: 'NotFound', message: 'No pending deletion request found' });
    }
    if (new Date(req.expires_at) < new Date()) {
        return reply.code(400).send({ error: 'TokenExpired', message: 'Deletion token has expired' });
    }
    // Soft-delete: anonymize email in public.users
    await supabase
        .from('users')
        .update({ email: `deleted_user_${user.sub}@deleted.invalid` })
        .eq('id', user.sub);
    await supabase
        .from('deletion_requests')
        .update({ executed_at: new Date().toISOString(), confirmed_at: new Date().toISOString() })
        .eq('user_id', user.sub);
    return reply.send({ message: 'Account successfully deleted.' });
};

export const getUserPreferences = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const { data, error } = await supabase
        .from('user_preferences')
        .upsert({ user_id: user.sub, updated_at: new Date().toISOString() }, { onConflict: 'user_id', ignoreDuplicates: false })
        .select('*')
        .single();
    if (error) throw error;
    return reply.send(data);
};

export const updateUserPreferences = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const { allergies, dietary_tags, cuisine_blacklist } = request.body as {
        allergies?: string[];
        dietary_tags?: string[];
        cuisine_blacklist?: string[];
    };
    const updates: Record<string, any> = { updated_at: new Date().toISOString() };
    if (allergies !== undefined) updates.allergies = allergies;
    if (dietary_tags !== undefined) updates.dietary_tags = dietary_tags;
    if (cuisine_blacklist !== undefined) updates.cuisine_blacklist = cuisine_blacklist;
    const { data, error } = await supabase
        .from('user_preferences')
        .upsert({ user_id: user.sub, ...updates }, { onConflict: 'user_id' })
        .select('*')
        .single();
    if (error) throw error;
    return reply.send(data);
};
