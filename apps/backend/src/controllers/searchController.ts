import { FastifyRequest, FastifyReply } from 'fastify';
import { supabase } from '../services/supabase';

export const globalSearch = async (request: FastifyRequest, reply: FastifyReply) => {
    const { q } = request.query as any;

    if (!q) {
        const err = new Error('Search query "q" is required') as any;
        err.statusCode = 400;
        throw err;
    }

    // Search menu_items and join with vendors
    const { data, error } = await supabase
        .from('menu_items')
        .select(`
            *,
            menus (
                vendor_id,
                vendors (
                    id,
                    name,
                    description,
                    image_url
                )
            )
        `)
        .or(`name.ilike.%${q}%,description.ilike.%${q}%`)
        .eq('is_available', true);

    if (error) throw error;

    // Flatten the response for easier consumption
    const results = data.map((item: any) => ({
        id: item.id,
        name: item.name,
        description: item.description,
        price: item.price,
        image_url: item.image_url,
        vendor: item.menus?.vendors || null
    }));

    return reply.send(results);
};
