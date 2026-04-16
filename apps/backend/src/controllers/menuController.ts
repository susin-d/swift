import { FastifyRequest, FastifyReply } from 'fastify';
import { supabase } from '../services/supabase';
import { uploadMenuItemImage, validateImageFile } from '../services/storageService';

const resolveActorVendorId = async (user: any) => {
    if (!user?.sub) {
        const err = new Error('Authentication required') as any;
        err.statusCode = 401;
        throw err;
    }

    const role = String(user.role || '').toLowerCase();
    if (role === 'admin') {
        return null as string | null;
    }

    const ownerVendorQuery = supabase
        .from('vendors')
        .select('id')
        .eq('owner_id', user.sub) as any;
    const { data: ownerVendor } = ownerVendorQuery?.maybeSingle
        ? await ownerVendorQuery.maybeSingle()
        : await ownerVendorQuery.single();

    if (ownerVendor?.id) {
        return ownerVendor.id as string;
    }

    let staffMembershipQuery: any = supabase
        .from('vendor_staff_members')
        .select('vendor_id')
        .eq('user_id', user.sub)
        .eq('status', 'active');

    if (staffMembershipQuery?.order) {
        staffMembershipQuery = staffMembershipQuery.order('updated_at', { ascending: false });
    }
    if (staffMembershipQuery?.limit) {
        staffMembershipQuery = staffMembershipQuery.limit(1);
    }
    const { data: staffMembership } = staffMembershipQuery?.maybeSingle
        ? await staffMembershipQuery.maybeSingle()
        : (staffMembershipQuery?.single
            ? await staffMembershipQuery.single()
            : { data: null });

    if (staffMembership?.vendor_id) {
        return String(staffMembership.vendor_id);
    }

    const err = new Error('Vendor profile not found') as any;
    err.statusCode = 404;
    throw err;
};

const assertVendorScope = (actorVendorId: string | null, resourceVendorId: string) => {
    if (!actorVendorId) return;
    if (actorVendorId === resourceVendorId) return;

    const err = new Error('You do not have permission to access this resource') as any;
    err.statusCode = 403;
    throw err;
};

// Menu Controllers
export const createMenu = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const { vendor_id, category_name, sort_order } = request.body as any;
    const actorVendorId = await resolveActorVendorId(user);

    const nextVendorId = actorVendorId || vendor_id;
    if (!nextVendorId) {
        const err = new Error('vendor_id is required') as any;
        err.statusCode = 400;
        throw err;
    }

    assertVendorScope(actorVendorId, nextVendorId);

    const { data, error } = await supabase
        .from('menus')
        .insert({ vendor_id: nextVendorId, category_name, sort_order })
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
    const user = request.user as any;
    const { id } = request.params as any;
    const { category_name, sort_order } = request.body as any;
    const updated_at = new Date().toISOString();
    const actorVendorId = await resolveActorVendorId(user);

    const { data: existingMenu, error: existingMenuError } = await supabase
        .from('menus')
        .select('id, vendor_id')
        .eq('id', id)
        .maybeSingle();

    if (existingMenuError) throw existingMenuError;
    if (!existingMenu?.id) {
        const err = new Error('Menu not found') as any;
        err.statusCode = 404;
        throw err;
    }

    assertVendorScope(actorVendorId, String(existingMenu.vendor_id));

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
    const user = request.user as any;
    const { id } = request.params as any;
    const actorVendorId = await resolveActorVendorId(user);

    const { data: existingMenu, error: existingMenuError } = await supabase
        .from('menus')
        .select('id, vendor_id')
        .eq('id', id)
        .maybeSingle();

    if (existingMenuError) throw existingMenuError;
    if (!existingMenu?.id) {
        const err = new Error('Menu not found') as any;
        err.statusCode = 404;
        throw err;
    }

    assertVendorScope(actorVendorId, String(existingMenu.vendor_id));

    const { error } = await supabase
        .from('menus')
        .delete()
        .eq('id', id);

    if (error) throw error;
    return reply.code(204).send();
};

// Menu Item Controllers
export const createMenuItem = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const { menu_id, name, description, price, is_available, image_url } = request.body as any;
    const actorVendorId = await resolveActorVendorId(user);

    const { data: menu, error: menuError } = await supabase
        .from('menus')
        .select('id, vendor_id')
        .eq('id', menu_id)
        .maybeSingle();

    if (menuError) throw menuError;
    if (!menu?.id) {
        const err = new Error('Menu not found') as any;
        err.statusCode = 404;
        throw err;
    }

    assertVendorScope(actorVendorId, String(menu.vendor_id));

    const { data, error } = await supabase
        .from('menu_items')
        .insert({ menu_id, name, description, price, is_available, image_url })
        .select()
        .single();

    if (error) throw error;
    return reply.code(201).send(data);
};

export const updateMenuItem = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const { id } = request.params as any;
    const actorVendorId = await resolveActorVendorId(user);

    const { data: existingItem, error: existingItemError } = await supabase
        .from('menu_items')
        .select('id, menu_id')
        .eq('id', id)
        .maybeSingle();

    if (existingItemError) throw existingItemError;
    if (!existingItem?.id) {
        const err = new Error('Menu item not found') as any;
        err.statusCode = 404;
        throw err;
    }

    const { data: menu, error: menuError } = await supabase
        .from('menus')
        .select('vendor_id')
        .eq('id', existingItem.menu_id)
        .maybeSingle();

    if (menuError) throw menuError;
    if (!menu?.vendor_id) {
        const err = new Error('Menu not found') as any;
        err.statusCode = 404;
        throw err;
    }

    assertVendorScope(actorVendorId, String(menu.vendor_id));

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
    const user = request.user as any;
    const { id } = request.params as any;
    const actorVendorId = await resolveActorVendorId(user);

    const { data: existingItem, error: existingItemError } = await supabase
        .from('menu_items')
        .select('id, menu_id')
        .eq('id', id)
        .maybeSingle();

    if (existingItemError) throw existingItemError;
    if (!existingItem?.id) {
        const err = new Error('Menu item not found') as any;
        err.statusCode = 404;
        throw err;
    }

    const { data: menu, error: menuError } = await supabase
        .from('menus')
        .select('vendor_id')
        .eq('id', existingItem.menu_id)
        .maybeSingle();

    if (menuError) throw menuError;
    if (!menu?.vendor_id) {
        const err = new Error('Menu not found') as any;
        err.statusCode = 404;
        throw err;
    }

    assertVendorScope(actorVendorId, String(menu.vendor_id));

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
    const vendorId = (request.user as any)?.sub;
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
    const vendorId = await resolveActorVendorId(user);

    if (!vendorId) {
        const err = new Error('vendor_id is required for admin context') as any;
        err.statusCode = 400;
        throw err;
    }

    const { data, error } = await supabase
        .from('menus')
        .select('*, menu_items(*)')
        .eq('vendor_id', vendorId);

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
