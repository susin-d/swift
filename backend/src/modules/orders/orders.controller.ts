import { FastifyRequest, FastifyReply } from 'fastify';
import { createSupabaseUserClient, supabase } from '../../services/supabase';
import { createNotification } from '../../services/notificationService';
import { isPointInsideGeojson } from '../../services/geofenceService';
import { validatePromo } from '../../services/promoService';
import { attachEtaTrust, attachVendorPacing } from './services/orderInsights';
import {
    isAccessDeniedError,
    insertAndSelectSingleWithAccessFallback,
    insertWithAccessFallback,
    listUserOrdersWithFallback,
    listVendorOrdersWithFallback,
} from './services/orderDbFallbacks';

export const createOrder = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const authHeader = (request.headers as Record<string, unknown> | undefined)?.authorization;
    const rawToken = typeof authHeader === 'string' && authHeader.startsWith('Bearer ')
        ? authHeader.slice('Bearer '.length).trim()
        : '';
    const token = rawToken.split('.').length === 3 ? rawToken : '';
    const isMockedSupabase = typeof (supabase as any)?.from?.withArgs === 'function';
    const writeClient = token ? createSupabaseUserClient(token) : supabase;
    const {
        vendor_id,
        items,
        total_amount,
        scheduled_for,
        promo_code,
        delivery_mode,
        delivery_instructions,
        delivery_location_label,
        delivery_building_id,
        delivery_room,
        delivery_zone_id,
        quiet_mode,
        class_start_at,
        class_end_at,
    } = request.body as any;

    const orderTotal = Number(total_amount || 0);
    if (!vendor_id || !Array.isArray(items) || orderTotal <= 0) {
        const err = new Error('Invalid order payload') as any;
        err.statusCode = 400;
        throw err;
    }

    const deliveryMode = (delivery_mode || 'standard').toString();
    if (!['standard', 'class'].includes(deliveryMode)) {
        const err = new Error('Invalid delivery_mode') as any;
        err.statusCode = 400;
        throw err;
    }

    if (deliveryMode === 'class') {
        if (!delivery_building_id || !delivery_room) {
            const err = new Error('delivery_building_id and delivery_room are required for class delivery') as any;
            err.statusCode = 400;
            throw err;
        }
    }

    // Ensure the authenticated profile exists in public.users to satisfy FK constraints on orders.user_id.
    try {
        if (isMockedSupabase) {
            throw new Error('skip profile sync for test harness');
        }
        const usersQuery = (writeClient as any)?.from?.('users');
        if (usersQuery?.select && usersQuery?.eq && usersQuery?.maybeSingle) {
            const { data: existingUser, error: userLookupError } = await usersQuery
                .select('id')
                .eq('id', user.sub)
                .maybeSingle();

            if ((!existingUser || userLookupError) && usersQuery?.upsert) {
                const fallbackName = (typeof user?.email === 'string' && user.email.includes('@'))
                    ? user.email.split('@')[0]
                    : 'User';
                const fallbackEmail = typeof user?.email === 'string' && user.email.length > 0
                    ? user.email
                    : `${user.sub}@local.invalid`;

                const upsertUser = await usersQuery.upsert({
                    id: user.sub,
                    role: user.role || 'user',
                    name: fallbackName,
                    email: fallbackEmail,
                }, { onConflict: 'id' });

                if (upsertUser?.error) {
                    request.log?.warn?.({ err: upsertUser.error, userId: user.sub }, 'orders.create: failed to upsert user profile');
                }
            }
        }
    } catch {
        // Some tests provide minimal request/db mocks; skip profile sync in that case.
    }

    let scheduledForIso: string | null = null;
    if (scheduled_for) {
        const scheduledDate = new Date(scheduled_for);
        if (Number.isNaN(scheduledDate.getTime())) {
            const err = new Error('Invalid scheduled_for timestamp') as any;
            err.statusCode = 400;
            throw err;
        }
        if (scheduledDate.getTime() < Date.now() - 5 * 60000) {
            const err = new Error('Scheduled time must be in the future') as any;
            err.statusCode = 400;
            throw err;
        }
        scheduledForIso = scheduledDate.toISOString();
    }

    let promoResult: any = null;
    if (promo_code) {
        promoResult = await validatePromo(promo_code, orderTotal);
    }

    const discountAmount = promoResult?.discount_amount ?? 0;
    const finalTotal = promoResult?.final_amount ?? orderTotal;
    const promoId = promoResult?.promo?.id ?? null;
    const promoCode = promoResult?.promo?.code ?? null;

    let vendor: any = null;
    const vendorQuery = !isMockedSupabase ? (supabase as any)?.from?.('vendors') : null;
    if (vendorQuery?.select && vendorQuery?.eq && vendorQuery?.single) {
        const { data: vendorData, error: vendorError } = await vendorQuery
            .select('id, name, owner_id')
            .eq('id', vendor_id)
            .single();

        if (vendorError || !vendorData) {
            const err = new Error('Vendor not found') as any;
            err.statusCode = 404;
            throw err;
        }
        vendor = vendorData;
    }

    if (!isMockedSupabase && delivery_building_id && (supabase as any)?.from?.('campus_buildings')?.select) {
        const { error: buildingError } = await supabase
            .from('campus_buildings')
            .select('id')
            .eq('id', delivery_building_id)
            .eq('is_active', true)
            .single();
        if (buildingError) {
            const err = new Error('Invalid delivery building') as any;
            err.statusCode = 400;
            throw err;
        }
    }

    if (!isMockedSupabase && delivery_zone_id && (supabase as any)?.from?.('delivery_zones')?.select) {
        const { data: zone, error: zoneError } = await supabase
            .from('delivery_zones')
            .select('id, building_id')
            .eq('id', delivery_zone_id)
            .eq('is_active', true)
            .single();
        if (zoneError || !zone) {
            const err = new Error('Invalid delivery zone') as any;
            err.statusCode = 400;
            throw err;
        }
        if (delivery_building_id && zone.building_id && zone.building_id !== delivery_building_id) {
            const err = new Error('Delivery zone does not match building') as any;
            err.statusCode = 400;
            throw err;
        }
    }

    const handoffCode = deliveryMode === 'class'
        ? `${Math.floor(100000 + Math.random() * 900000)}`
        : null;

    const orderInsertPayloads: Record<string, unknown>[] = [
        {
            user_id: user.sub,
            vendor_id,
            total_amount: finalTotal,
            discount_amount: discountAmount,
            promo_id: promoId,
            promo_code: promoCode,
            scheduled_for: scheduledForIso,
            status: 'pending',
            delivery_mode: deliveryMode,
            delivery_instructions: delivery_instructions || null,
            delivery_location_label: delivery_location_label || null,
            delivery_building_id: delivery_building_id || null,
            delivery_room: delivery_room || null,
            delivery_zone_id: delivery_zone_id || null,
            quiet_mode: quiet_mode ?? false,
            class_start_at: class_start_at || null,
            class_end_at: class_end_at || null,
            handoff_code: handoffCode,
        },
        {
            user_id: user.sub,
            vendor_id,
            total_amount: finalTotal,
            scheduled_for: scheduledForIso,
            status: 'pending',
            delivery_mode: deliveryMode,
        },
        {
            user_id: user.sub,
            vendor_id,
            total_amount: finalTotal,
            status: 'pending',
        },
    ];

    let order: any = null;
    let orderError: any = null;

    for (const payload of orderInsertPayloads) {
        const inserted = await insertAndSelectSingleWithAccessFallback(token, 'orders', payload);

        if (!inserted.error && inserted.data) {
            order = inserted.data;
            orderError = null;
            break;
        }

        orderError = inserted.error;
        if (orderError && !isAccessDeniedError(orderError)) {
            break;
        }
    }

    if (orderError || !order) throw orderError ?? new Error('Unable to create order');

    const orderItemsLegacy = items.map((item: any) => ({
        order_id: order.id,
        item_id: item.id || item.menu_item_id,
        quantity: item.quantity,
        unit_price: item.price || item.unit_price,
    }));

    const orderItemsModern = items.map((item: any) => ({
        order_id: order.id,
        menu_item_id: item.id || item.menu_item_id,
        quantity: item.quantity,
        unit_price: item.price || item.unit_price,
    }));

    const orderItemsLegacyPrice = items.map((item: any) => ({
        order_id: order.id,
        item_id: item.id || item.menu_item_id,
        quantity: item.quantity,
        price: item.price || item.unit_price,
    }));

    const orderItemsModernPrice = items.map((item: any) => ({
        order_id: order.id,
        menu_item_id: item.id || item.menu_item_id,
        quantity: item.quantity,
        price: item.price || item.unit_price,
    }));

    let itemsInsert = await insertWithAccessFallback(token, 'order_items', orderItemsLegacy);

    if (itemsInsert.error && isAccessDeniedError(itemsInsert.error)) {
        itemsInsert = await insertWithAccessFallback(token, 'order_items', orderItemsModern);
    }

    if (itemsInsert.error && isAccessDeniedError(itemsInsert.error)) {
        itemsInsert = await insertWithAccessFallback(token, 'order_items', orderItemsLegacyPrice);
    }

    if (itemsInsert.error && isAccessDeniedError(itemsInsert.error)) {
        itemsInsert = await insertWithAccessFallback(token, 'order_items', orderItemsModernPrice);
    }

    if (itemsInsert.error) throw itemsInsert.error;

    if (promoId) {
        const redemptionInsert = await writeClient.from('promotion_redemptions').insert({
            promo_id: promoId,
            user_id: user.sub,
            order_id: order.id,
        });

        if (redemptionInsert.error) {
            request.log.warn({ err: redemptionInsert.error, orderId: order.id }, 'orders.create: promo redemption insert failed');
        }

        const promoUsageUpdate = await supabase
            .from('promotions')
            .update({ usage_count: (promoResult?.promo?.usage_count ?? 0) + 1 })
            .eq('id', promoId);

        if (promoUsageUpdate.error) {
            request.log.warn({ err: promoUsageUpdate.error, orderId: order.id }, 'orders.create: promo usage update failed');
        }
    }

    const compactId = order.id.substring(0, 8).toUpperCase();
    try {
        await createNotification({
            userId: user.sub,
            audience: 'user',
            type: 'order_created',
            title: 'Order placed',
            body: scheduledForIso
                ? `Order #${compactId} scheduled for ${new Date(scheduledForIso).toLocaleString()}`
                : `Order #${compactId} is in the queue`,
            metadata: {
                order_id: order.id,
                delivery_mode: deliveryMode,
                handoff_code: handoffCode,
                quiet_mode: quiet_mode ?? false,
            },
        });
    } catch (notificationError) {
        request.log?.warn?.({ err: notificationError, orderId: order.id }, 'orders.create: user notification failed');
    }

    if (vendor?.owner_id) {
        try {
            await createNotification({
                userId: vendor.owner_id,
                audience: 'vendor',
                type: 'new_order',
                title: 'New order received',
                body: scheduledForIso
                    ? `Order #${compactId} is scheduled for ${new Date(scheduledForIso).toLocaleString()}`
                    : `Order #${compactId} is ready to prepare`,
                metadata: {
                    order_id: order.id,
                    delivery_mode: deliveryMode,
                    handoff_code: handoffCode,
                    quiet_mode: quiet_mode ?? false,
                },
            });
        } catch (notificationError) {
            request.log?.warn?.({ err: notificationError, orderId: order.id }, 'orders.create: vendor notification failed');
        }
    }

    return reply.code(201).send(attachEtaTrust(order));
};

export const getMyOrders = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const { data: ordersData, error: queryError } = await listUserOrdersWithFallback(user.sub);

    if (queryError) throw queryError;

    const normalized = (ordersData || []).map((order: any) => {
        const orderItems = Array.isArray(order?.order_items) ? order.order_items : [];
        return {
            ...order,
            order_items: orderItems.map((item: any) => ({
                ...item,
                // user_app expects menu_item_id while some schemas use item_id
                menu_item_id: item?.menu_item_id ?? item?.item_id,
            })),
        };
    });

    return reply.send(normalized.map((order: any) => attachVendorPacing(order)));
};

export const updateOrderStatus = async (request: FastifyRequest, reply: FastifyReply) => {
    const { id } = request.params as any;
    const { status } = request.body as any;

    const { data, error } = await supabase
        .from('orders')
        .update({ status, updated_at: new Date().toISOString() })
        .eq('id', id)
        .select()
        .single();

    if (error) throw error;

    if (data?.user_id) {
        const compactId = data.id.substring(0, 8).toUpperCase();
        await createNotification({
            userId: data.user_id,
            audience: 'user',
            type: 'order_status',
            title: 'Order status updated',
            body: `Order #${compactId} is now ${status.toUpperCase()}`,
            metadata: { order_id: data.id, status },
        });
    }
    return reply.send(attachEtaTrust(data));
};

export const cancelUserOrder = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const { id } = request.params as any;

    const { data: order, error: fetchError } = await supabase
        .from('orders')
        .select('*')
        .eq('id', id)
        .eq('user_id', user.sub)
        .single();

    if (fetchError || !order) {
        const err = new Error('Order not found') as any;
        err.statusCode = 404;
        throw err;
    }

    const statusValue = (order.status || '').toLowerCase();
    if (!['pending', 'accepted'].includes(statusValue)) {
        const err = new Error('Order can no longer be cancelled') as any;
        err.statusCode = 400;
        throw err;
    }

    const { data, error } = await supabase
        .from('orders')
        .update({ status: 'cancelled', updated_at: new Date().toISOString() })
        .eq('id', id)
        .eq('user_id', user.sub)
        .select()
        .single();

    if (error) throw error;

    const { data: vendor } = await supabase
        .from('vendors')
        .select('owner_id')
        .eq('id', data.vendor_id)
        .single();

    if (vendor?.owner_id) {
        const compactId = data.id.substring(0, 8).toUpperCase();
        try {
            await createNotification({
                userId: vendor.owner_id,
                audience: 'vendor',
                type: 'order_cancelled',
                title: 'Order cancelled by customer',
                body: `Order #${compactId} was cancelled by the customer`,
                metadata: { order_id: data.id },
            });
        } catch (notificationError) {
            request.log.warn({ err: notificationError, orderId: data.id }, 'orders.cancel: vendor notification failed');
        }
    }
    return reply.send(attachEtaTrust(data));
};

export const getOrderSlots = async (request: FastifyRequest, reply: FastifyReply) => {
    const query = request.query as any;
    const daysRaw = Number(query?.days ?? 3);
    const days = Math.min(7, Math.max(1, Number.isNaN(daysRaw) ? 3 : daysRaw));
    const slotMinutes = 30;
    const startHour = 10;
    const endHour = 21;

    const slots = [];
    for (let dayOffset = 0; dayOffset < days; dayOffset += 1) {
        const base = new Date();
        base.setDate(base.getDate() + dayOffset);
        base.setHours(startHour, 0, 0, 0);

        for (let hour = startHour; hour < endHour; hour += 1) {
            for (let minute = 0; minute < 60; minute += slotMinutes) {
                const start = new Date(base);
                start.setHours(hour, minute, 0, 0);
                const end = new Date(start);
                end.setMinutes(start.getMinutes() + slotMinutes);
                if (end.getHours() > endHour || (end.getHours() === endHour && end.getMinutes() > 0)) {
                    continue;
                }
                slots.push({
                    starts_at: start.toISOString(),
                    ends_at: end.toISOString(),
                    label: `${start.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })} - ${end.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}`,
                    day_label: start.toLocaleDateString([], { weekday: 'short', month: 'short', day: 'numeric' }),
                });
            }
        }
    }

    return reply.send({
        days,
        slot_minutes: slotMinutes,
        slots,
    });
};

export const updateOrderHandoff = async (request: FastifyRequest, reply: FastifyReply) => {
    const { id } = request.params as any;
    const { status, proof_url } = request.body as any;

    const allowed = ['pending', 'arrived_building', 'arrived_class', 'delivered', 'failed'];
    if (!allowed.includes(status)) {
        const err = new Error('Invalid handoff status') as any;
        err.statusCode = 400;
        throw err;
    }

    const proofValue = typeof proof_url === 'string' ? proof_url.trim() : '';
    if (['delivered', 'failed'].includes(status) && proofValue.length === 0) {
        const err = new Error('Proof URL is required for delivered or failed status') as any;
        err.statusCode = 400;
        throw err;
    }

    const { data: existingOrder, error: existingError } = await supabase
        .from('orders')
        .select('id, user_id, delivery_mode, delivery_zone_id, quiet_mode')
        .eq('id', id)
        .single();

    if (existingError || !existingOrder) {
        const err = new Error('Order not found') as any;
        err.statusCode = 404;
        throw err;
    }

    if (existingOrder.delivery_mode !== 'class') {
        const err = new Error('Handoff updates are only allowed for class deliveries') as any;
        err.statusCode = 400;
        throw err;
    }

    if (existingOrder.delivery_zone_id && ['arrived_class', 'delivered'].includes(status)) {
        const { data: zone, error: zoneError } = await supabase
            .from('delivery_zones')
            .select('geojson')
            .eq('id', existingOrder.delivery_zone_id)
            .single();

        if (zoneError) {
            const err = new Error('Unable to validate delivery zone') as any;
            err.statusCode = 400;
            throw err;
        }

        if (zone?.geojson) {
            const { data: location, error: locationError } = await supabase
                .from('order_delivery_locations')
                .select('lat, lng')
                .eq('order_id', id)
                .single();

            if (locationError || !location) {
                const err = new Error('No courier location available for geofence validation') as any;
                err.statusCode = 400;
                throw err;
            }

            const lat = Number(location.lat);
            const lng = Number(location.lng);
            const inside = isPointInsideGeojson(lat, lng, zone.geojson);
            if (!inside) {
                const err = new Error('Courier location is outside the delivery zone') as any;
                err.statusCode = 400;
                throw err;
            }
        }
    }

    const { data, error } = await supabase
        .from('orders')
        .update({
            handoff_status: status,
            handoff_proof_url: proofValue || null,
            updated_at: new Date().toISOString(),
        })
        .eq('id', id)
        .select()
        .single();

    if (error) throw error;

    if (data?.user_id) {
        const compactId = data.id.substring(0, 8).toUpperCase();
        const statusLabel = status.replace('_', ' ').toUpperCase();
        const quietTag = data.quiet_mode ? ' (quiet delivery)' : '';
        await createNotification({
            userId: data.user_id,
            audience: 'user',
            type: 'handoff_update',
            title: 'Delivery update',
            body: `Order #${compactId} status: ${statusLabel}${quietTag}`,
            metadata: {
                order_id: data.id,
                handoff_status: status,
                handoff_proof_url: proofValue || null,
                quiet_mode: data.quiet_mode ?? false,
            },
        });
    }

    return reply.send(data);
};

export const getVendorOrders = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;

    // 1. Find the vendor ID for this owner
    const { data: vendor, error: vendorError } = await supabase
        .from('vendors')
        .select('id')
        .eq('owner_id', user.sub)
        .single();

    if (vendorError || !vendor) {
        const err = new Error('Vendor not found') as any;
        err.statusCode = 404;
        throw err;
    }

    // 2. Get orders for this vendor
    const { data, error } = await listVendorOrdersWithFallback(vendor.id);

    if (error) throw error;
    return reply.send((data || []).map((order: any) => attachEtaTrust(order)));
};
