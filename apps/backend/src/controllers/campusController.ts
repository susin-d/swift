import { FastifyReply, FastifyRequest } from 'fastify';
import { supabase } from '../services/supabase';

export const listPublicBuildings = async (_request: FastifyRequest, reply: FastifyReply) => {
    const { data, error } = await supabase
        .from('campus_buildings')
        .select('*')
        .eq('is_active', true)
        .order('name', { ascending: true });

    if (error) throw error;
    return reply.send(data || []);
};

export const listPublicZones = async (request: FastifyRequest, reply: FastifyReply) => {
    const { building_id } = (request.query as any) ?? {};
    let query = supabase
        .from('delivery_zones')
        .select('*')
        .eq('is_active', true);

    if (building_id) {
        query = query.eq('building_id', building_id);
    }

    const { data, error } = await query.order('name', { ascending: true });
    if (error) throw error;
    return reply.send(data || []);
};

export const adminListBuildings = async (_request: FastifyRequest, reply: FastifyReply) => {
    const { data, error } = await supabase
        .from('campus_buildings')
        .select('*')
        .order('name', { ascending: true });

    if (error) throw error;
    return reply.send(data || []);
};

export const adminCreateBuilding = async (request: FastifyRequest, reply: FastifyReply) => {
    const payload = request.body as any;
    if (!payload?.name) {
        const err = new Error('Building name is required') as any;
        err.statusCode = 400;
        throw err;
    }

    const record = {
        name: payload.name,
        code: payload.code || null,
        address: payload.address || null,
        latitude: payload.latitude ?? null,
        longitude: payload.longitude ?? null,
        delivery_notes: payload.delivery_notes || null,
        is_active: payload.is_active ?? true,
    };

    const { data, error } = await supabase
        .from('campus_buildings')
        .insert(record)
        .select()
        .single();

    if (error) throw error;
    return reply.code(201).send(data);
};

export const adminUpdateBuilding = async (request: FastifyRequest, reply: FastifyReply) => {
    const { id } = request.params as any;
    const payload = request.body as any;

    const updates: Record<string, any> = {};
    if (payload.name !== undefined) updates.name = payload.name;
    if (payload.code !== undefined) updates.code = payload.code;
    if (payload.address !== undefined) updates.address = payload.address;
    if (payload.latitude !== undefined) updates.latitude = payload.latitude;
    if (payload.longitude !== undefined) updates.longitude = payload.longitude;
    if (payload.delivery_notes !== undefined) updates.delivery_notes = payload.delivery_notes;
    if (payload.is_active !== undefined) updates.is_active = payload.is_active;

    const { data, error } = await supabase
        .from('campus_buildings')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    if (error) throw error;
    return reply.send(data);
};

export const adminListZones = async (_request: FastifyRequest, reply: FastifyReply) => {
    const { data, error } = await supabase
        .from('delivery_zones')
        .select('*')
        .order('name', { ascending: true });

    if (error) throw error;
    return reply.send(data || []);
};

export const adminCreateZone = async (request: FastifyRequest, reply: FastifyReply) => {
    const payload = request.body as any;
    if (!payload?.name) {
        const err = new Error('Zone name is required') as any;
        err.statusCode = 400;
        throw err;
    }

    const record = {
        name: payload.name,
        building_id: payload.building_id || null,
        geojson: payload.geojson || null,
        is_active: payload.is_active ?? true,
    };

    const { data, error } = await supabase
        .from('delivery_zones')
        .insert(record)
        .select()
        .single();

    if (error) throw error;
    return reply.code(201).send(data);
};

export const adminUpdateZone = async (request: FastifyRequest, reply: FastifyReply) => {
    const { id } = request.params as any;
    const payload = request.body as any;

    const updates: Record<string, any> = {};
    if (payload.name !== undefined) updates.name = payload.name;
    if (payload.building_id !== undefined) updates.building_id = payload.building_id;
    if (payload.geojson !== undefined) updates.geojson = payload.geojson;
    if (payload.is_active !== undefined) updates.is_active = payload.is_active;

    const { data, error } = await supabase
        .from('delivery_zones')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    if (error) throw error;
    return reply.send(data);
};
