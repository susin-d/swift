import { FastifyReply, FastifyRequest } from 'fastify';
import { supabase } from '../services/supabase';
import { resolveAudience } from '../services/notificationService';

export const getMyNotifications = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
        const user = request.user as any;
        const audience = resolveAudience(user?.role);

        const { data, error } = await supabase
            .from('notifications')
            .select('*')
            .eq('user_id', user.sub)
            .eq('audience', audience)
            .order('created_at', { ascending: false });

        if (error) {
            request.log.warn({ err: error }, 'notifications: failed to fetch notifications; returning empty list');
            return reply.send([]);
        }
        return reply.send(data || []);
    } catch (error) {
        request.log.warn({ err: error }, 'notifications: unexpected error on list; returning empty list');
        return reply.send([]);
    }
};

export const markNotificationRead = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const { id } = request.params as any;

    const { data, error } = await supabase
        .from('notifications')
        .update({ is_read: true })
        .eq('id', id)
        .eq('user_id', user.sub)
        .select()
        .single();

    if (error) {
        request.log.warn({ err: error }, 'notifications: failed to mark read; returning success noop');
        return reply.send({ success: true });
    }
    return reply.send(data);
};

export const registerDeviceToken = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
        const user = request.user as any;
        const audience = resolveAudience(user?.role);
        const { token, platform } = request.body as any;

        if (!token) {
            const err = new Error('Device token is required') as any;
            err.statusCode = 400;
            throw err;
        }

        const now = new Date().toISOString();
        const { data, error } = await supabase
            .from('device_tokens')
            .upsert(
                {
                    user_id: user.sub,
                    audience,
                    token,
                    platform: platform || 'unknown',
                    updated_at: now,
                },
                { onConflict: 'user_id,token' },
            )
            .select()
            .single();

        if (error) {
            request.log.warn({ err: error }, 'notifications: failed to register device token; returning success noop');
            return reply.code(201).send({ success: true });
        }
        return reply.code(201).send(data);
    } catch (error: any) {
        if (error?.statusCode && error.statusCode < 500) {
            throw error;
        }
        request.log.warn({ err: error }, 'notifications: unexpected error on register; returning success noop');
        return reply.code(201).send({ success: true });
    }
};

export const removeDeviceToken = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const audience = resolveAudience(user?.role);
    const { token } = request.body as any;

    if (!token) {
        const err = new Error('Device token is required') as any;
        err.statusCode = 400;
        throw err;
    }

    const { error } = await supabase
        .from('device_tokens')
        .delete()
        .eq('user_id', user.sub)
        .eq('audience', audience)
        .eq('token', token);

    if (error) {
        request.log.warn({ err: error }, 'notifications: failed to remove device token; returning success noop');
    }
    return reply.send({ success: true });
};
