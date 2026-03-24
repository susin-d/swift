import { FastifyRequest, FastifyReply } from 'fastify';
import { supabase } from '../services/supabase';
import { uploadMenuItemImage, validateImageFile } from '../services/storageService';

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
    const updated_at = new Date().toISOString();

    const { data, error } = await supabase
        .from('menus')
        .update({ category_name, sort_order, updated_at })
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
    const updateData = {
        ...(request.body as any),
        updated_at: new Date().toISOString(),
    };

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

/**
 * Upload a menu item image to storage and return HTTPS URL.
 * 
 * Request body:
 * {
 *   "imageData": "base64-encoded-image-bytes",
 *   "mimeType": "image/jpeg|image/png|image/webp|image/gif"
 * }
 * 
 * Response (201):
 * {
 *   "url": "https://{project}.supabase.co/storage/v1/object/public/menu-items/vendor/{vendorId}/items/{fileName}",
 *   "path": "vendor/{vendorId}/items/{fileName}",
 *   "mimeType": "image/jpeg",
 *   "sizeBytes": 12345
 * }
 * 
 * Error (400): File too large, invalid MIME type, or malformed base64
 * Error (500): Storage service error
 */
export const uploadMenuItemImageEndpoint = async (request: FastifyRequest, reply: FastifyReply) => {
    const vendorId = (request.user as any)?.id;
    if (!vendorId) {
        return reply.code(401).send({ error: 'unauthorized', message: 'Vendor authentication required' });
    }

    const { imageData, mimeType } = request.body as any;

    // Validate request payload
    if (!imageData || typeof imageData !== 'string') {
        return reply.code(400).send({ 
            error: 'bad_request', 
            message: 'imageData must be a non-empty base64 string' 
        });
    }
    if (!mimeType || typeof mimeType !== 'string') {
        return reply.code(400).send({ 
            error: 'bad_request', 
            message: 'mimeType must be specified (e.g., image/jpeg, image/png, image/webp, image/gif)' 
        });
    }

    try {
        // Validate file size and MIME type
        // (This will throw if validation fails)
        validateImageFile(imageData, mimeType);

        // Upload to storage
        const result = await uploadMenuItemImage(imageData, mimeType, {
            vendorId,
        });

        return reply.code(201).send(result);
    } catch (validationError) {
        const message = validationError instanceof Error ? validationError.message : 'Validation failed';
        
        // Determine if it's a validation error or storage error
        const isValidationError = message.includes('Invalid MIME type') || message.includes('File too large');
        const statusCode = isValidationError ? 400 : 500;
        const errorType = isValidationError ? 'validation_error' : 'storage_error';

        return reply.code(statusCode).send({ 
            error: errorType, 
            message 
        });
    }
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

    const categories = (data ?? []).map((category: any) => ({
        ...category,
        menu_items: (category.menu_items ?? []).slice().sort((a: any, b: any) => {
            const left = String(a?.name ?? '').toLowerCase();
            const right = String(b?.name ?? '').toLowerCase();
            return left.localeCompare(right);
        }),
    })).sort((a: any, b: any) => {
        const left = Number(a?.sort_order ?? 0);
        const right = Number(b?.sort_order ?? 0);
        return left - right;
    });

    // Flatten menu items while preserving all menu/category columns for clients that render cards from one list.
    const allItems = categories.flatMap((category: any) =>
        (category.menu_items ?? []).map((item: any) => ({
            ...item,
            category: category.category_name,
            category_name: category.category_name,
            category_id: category.id,
            category_sort_order: category.sort_order,
            vendor_id: category.vendor_id,
        })),
    );

    return reply.send({ items: allItems, categories });
};
