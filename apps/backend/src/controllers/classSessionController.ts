import { FastifyReply, FastifyRequest } from 'fastify';
import { supabase } from '../services/supabase';

export const listMyClassSessions = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const { data, error } = await supabase
        .from('class_sessions')
        .select('*, campus_buildings(name)')
        .eq('user_id', user.sub)
        .order('starts_at', { ascending: true });

    if (error) throw error;
    return reply.send(data || []);
};

export const createClassSession = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const payload = request.body as any;

    if (!payload?.building_id || !payload?.room) {
        const err = new Error('building_id and room are required') as any;
        err.statusCode = 400;
        throw err;
    }

    const record = {
        user_id: user.sub,
        building_id: payload.building_id,
        room: payload.room,
        course_label: payload.course_label || null,
        starts_at: payload.starts_at || null,
        ends_at: payload.ends_at || null,
        notes: payload.notes || null,
    };

    const { data, error } = await supabase
        .from('class_sessions')
        .insert(record)
        .select()
        .single();

    if (error) throw error;
    return reply.code(201).send(data);
};

export const updateClassSession = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const { id } = request.params as any;
    const payload = request.body as any;

    const updates: Record<string, any> = {};
    if (payload.building_id !== undefined) updates.building_id = payload.building_id;
    if (payload.room !== undefined) updates.room = payload.room;
    if (payload.course_label !== undefined) updates.course_label = payload.course_label;
    if (payload.starts_at !== undefined) updates.starts_at = payload.starts_at;
    if (payload.ends_at !== undefined) updates.ends_at = payload.ends_at;
    if (payload.notes !== undefined) updates.notes = payload.notes;

    const { data, error } = await supabase
        .from('class_sessions')
        .update(updates)
        .eq('id', id)
        .eq('user_id', user.sub)
        .select()
        .single();

    if (error) throw error;
    return reply.send(data);
};

export const deleteClassSession = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const { id } = request.params as any;

    const { error } = await supabase
        .from('class_sessions')
        .delete()
        .eq('id', id)
        .eq('user_id', user.sub);

    if (error) throw error;
    return reply.send({ success: true });
};
