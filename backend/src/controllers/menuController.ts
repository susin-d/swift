import { FastifyRequest, FastifyReply } from 'fastify';
import { supabase } from '../services/supabase';

// Menu Controllers
export const createMenu = async (request: FastifyRequest, reply: FastifyReply) => {
    const { vendor_id, category_name, sort_order } = request.body as any;

    const { data, error } = await supabase
        .from('menus')
        .insert({ vendor_id, category_name, sort_order })
        .select()
        .single();

    if (error) throw error;
    return reply.code(201).send(data);
};

export const getVendorMenus = async (request: FastifyRequest, reply: FastifyReply) => {
    const { vendorId } = request.params as any;

    const { data, error } = await supabase
        .from('menus')
        .select('*, menu_items(*)')
        .eq('vendor_id', vendorId);

    if (error) throw error;
    return reply.send(data);
};

export const updateMenu = async (request: FastifyRequest, reply: FastifyReply) => {
    const { id } = request.params as any;
    const { category_name, sort_order } = request.body as any;

    const { data, error } = await supabase
        .from('menus')
        .update({ category_name, sort_order })
        .eq('id', id)
        .select()
        .single();

    if (error) throw error;
    return reply.send(data);
};

export const deleteMenu = async (request: FastifyRequest, reply: FastifyReply) => {
    const { id } = request.params as any;

    const { error } = await supabase
        .from('menus')
        .delete()
        .eq('id', id);

    if (error) throw error;
    return reply.code(204).send();
};

// Menu Item Controllers
export const createMenuItem = async (request: FastifyRequest, reply: FastifyReply) => {
    const { menu_id, name, description, price, is_available, image_url } = request.body as any;

    const { data, error } = await supabase
        .from('menu_items')
        .insert({ menu_id, name, description, price, is_available, image_url })
        .select()
        .single();

    if (error) throw error;
    return reply.code(201).send(data);
};

export const updateMenuItem = async (request: FastifyRequest, reply: FastifyReply) => {
    const { id } = request.params as any;
    const updateData = request.body as any;

    const { data, error } = await supabase
        .from('menu_items')
        .update(updateData)
        .eq('id', id)
        .select()
        .single();

    if (error) throw error;
    return reply.send(data);
};

export const deleteMenuItem = async (request: FastifyRequest, reply: FastifyReply) => {
    const { id } = request.params as any;

    const { error } = await supabase
        .from('menu_items')
        .delete()
        .eq('id', id);

    if (error) throw error;
    return reply.code(204).send();
};

export const getMyVendorMenu = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;

    // Get the vendor for this user
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

    const { data, error } = await supabase
        .from('menus')
        .select('*, menu_items(*)')
        .eq('vendor_id', vendor.id);

    if (error) throw error;

    // Flatten menu items for the frontend as the UI expects a flat array for now or we can adjust UI
    const allItems = data?.flatMap(m => m.menu_items.map((item: any) => ({ ...item, category: m.category_name }))) || [];

    return reply.send({ items: allItems, categories: data });
};
