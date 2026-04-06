import { FastifyReply, FastifyRequest } from 'fastify';
import { supabase } from '../services/supabase';

const userFromRequest = (request: FastifyRequest) => request.user as { sub: string; role: string } | undefined;

const DELETION_WINDOW_DAYS = 7;

export const requestAccountDeletion = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = userFromRequest(request);
    if (!user?.sub) {
        return reply.code(401).send({ error: 'Unauthorized', message: 'Authentication required' });
    }

    const now = new Date();
    const deleteAfter = new Date(now);
    deleteAfter.setDate(deleteAfter.getDate() + DELETION_WINDOW_DAYS);

    const payload = {
        user_id: user.sub,
        status: 'scheduled',
        requested_at: now.toISOString(),
        delete_after: deleteAfter.toISOString(),
        cancelled_at: null,
    };

    const { data, error } = await supabase
        .from('user_deletion_requests')
        .upsert(payload, { onConflict: 'user_id' })
        .select('*')
        .single();

    if (error) throw error;
    return reply.send({
        deletion: data,
        message: `Account deletion scheduled. You can cancel within ${DELETION_WINDOW_DAYS} days.`,
    });
};

export const cancelAccountDeletion = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = userFromRequest(request);
    if (!user?.sub) {
        return reply.code(401).send({ error: 'Unauthorized', message: 'Authentication required' });
    }

    const { data: current, error: currentError } = await supabase
        .from('user_deletion_requests')
        .select('*')
        .eq('user_id', user.sub)
        .maybeSingle();

    if (currentError) throw currentError;
    if (!current) {
        return reply.code(404).send({ error: 'NotFound', message: 'No pending deletion request found' });
    }
    if (current.status !== 'scheduled') {
        return reply.code(400).send({ error: 'ValidationError', message: 'Deletion request is not cancellable' });
    }

    const { data, error } = await supabase
        .from('user_deletion_requests')
        .update({
            status: 'cancelled',
            cancelled_at: new Date().toISOString(),
        })
        .eq('user_id', user.sub)
        .select('*')
        .single();

    if (error) throw error;
    return reply.send({
        deletion: data,
        message: 'Account deletion request cancelled.',
    });
};

export const getAccountDeletionStatus = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = userFromRequest(request);
    if (!user?.sub) {
        return reply.code(401).send({ error: 'Unauthorized', message: 'Authentication required' });
    }

    const { data, error } = await supabase
        .from('user_deletion_requests')
        .select('*')
        .eq('user_id', user.sub)
        .maybeSingle();

    if (error) throw error;
    return reply.send({
        deletion: data || null,
    });
};

export const processDueDeletionRequests = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = userFromRequest(request);
    if (!user?.sub || user.role !== 'admin') {
        return reply.code(403).send({ error: 'Forbidden', message: 'Admin access required' });
    }

    const nowIso = new Date().toISOString();
    const { data: dueRows, error: dueError } = await supabase
        .from('user_deletion_requests')
        .select('*')
        .eq('status', 'scheduled')
        .lte('delete_after', nowIso)
        .limit(250);

    if (dueError) throw dueError;
    const due = dueRows || [];
    if (due.length === 0) {
        return reply.send({ processed: 0, users: [] });
    }

    const userIds = due.map((row: any) => row.user_id);
    const { error: markUsersError } = await supabase
        .from('users')
        .update({ role: 'blocked', updated_at: nowIso })
        .in('id', userIds);
    if (markUsersError) throw markUsersError;

    const { error: completeError } = await supabase
        .from('user_deletion_requests')
        .update({ status: 'completed' })
        .in('user_id', userIds);
    if (completeError) throw completeError;

    return reply.send({
        processed: userIds.length,
        users: userIds,
    });
};

export const listDeletionReminders = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = userFromRequest(request);
    if (!user?.sub || user.role !== 'admin') {
        return reply.code(403).send({ error: 'Forbidden', message: 'Admin access required' });
    }

    const now = new Date();
    const threeDays = new Date(now);
    threeDays.setDate(now.getDate() + 3);
    const { data, error } = await supabase
        .from('user_deletion_requests')
        .select('*')
        .eq('status', 'scheduled')
        .gte('delete_after', now.toISOString())
        .lte('delete_after', threeDays.toISOString())
        .order('delete_after', { ascending: true });
    if (error) throw error;

    return reply.send({ reminders: data || [] });
};
