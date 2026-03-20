import { FastifyReply, FastifyRequest } from 'fastify';
import { supabase } from '../services/supabase';

type MenuItemRow = {
    id: string;
    name: string;
    description: string | null;
    price: number | string;
    image_url: string | null;
    is_available: boolean | null;
    menus?: {
        category_name?: string | null;
        vendors?: {
            id: string;
            name: string;
            description?: string | null;
            image_url?: string | null;
            is_open?: boolean | null;
            status?: string | null;
        } | null;
    } | null;
};

type OrderItemHistoryRow = {
    item_id: string;
    quantity: number | null;
    orders?: {
        status?: string | null;
        created_at?: string | null;
    } | Array<{
        status?: string | null;
        created_at?: string | null;
    }> | null;
};

const clamp01 = (value: number) => Math.max(0, Math.min(1, value));

export const getRecommendedItems = async (request: FastifyRequest, reply: FastifyReply) => {
    const rawLimit = Number((request.query as { limit?: string | number } | undefined)?.limit ?? 12);
    const limit = Number.isFinite(rawLimit) ? Math.max(1, Math.min(30, Math.floor(rawLimit))) : 12;

    const { data: itemsData, error: itemsError } = await supabase
        .from('menu_items')
        .select(`
            id,
            name,
            description,
            price,
            image_url,
            is_available,
            menus (
                category_name,
                vendors (
                    id,
                    name,
                    description,
                    image_url,
                    is_open,
                    status
                )
            )
        `)
        .eq('is_available', true);

    if (itemsError) throw itemsError;

    const items = (itemsData ?? []) as MenuItemRow[];
    if (items.length === 0) {
        return reply.send([]);
    }

    const { data: orderHistoryData, error: orderHistoryError } = await supabase
        .from('order_items')
        .select(`
            item_id,
            quantity,
            orders (
                status,
                created_at
            )
        `)
        .limit(5000);

    if (orderHistoryError) throw orderHistoryError;

    const { data: reviewsData, error: reviewsError } = await supabase
        .from('reviews')
        .select('vendor_id, rating');

    if (reviewsError) throw reviewsError;

    const popularityByItem = new Map<string, number>();
    const recentByItem = new Map<string, number>();
    const recentCutoffMs = Date.now() - (7 * 24 * 60 * 60 * 1000);

    for (const row of ((orderHistoryData ?? []) as OrderItemHistoryRow[])) {
        const quantity = Math.max(0, Number(row.quantity ?? 0));
        const existing = popularityByItem.get(row.item_id) ?? 0;
        popularityByItem.set(row.item_id, existing + quantity);

        const orderMeta = Array.isArray(row.orders) ? row.orders[0] : row.orders;
        const createdAt = orderMeta?.created_at ? Date.parse(orderMeta.created_at) : NaN;
        const status = (orderMeta?.status ?? '').toLowerCase();
        const isActiveOrder = status !== 'cancelled' && status !== 'failed';

        if (isActiveOrder && Number.isFinite(createdAt) && createdAt >= recentCutoffMs) {
            const recentCount = recentByItem.get(row.item_id) ?? 0;
            recentByItem.set(row.item_id, recentCount + quantity);
        }
    }

    const vendorRatings = new Map<string, { total: number; count: number }>();
    for (const review of (reviewsData ?? []) as Array<{ vendor_id: string; rating: number }>) {
        const key = review.vendor_id;
        if (!key) continue;
        const bucket = vendorRatings.get(key) ?? { total: 0, count: 0 };
        bucket.total += Number(review.rating ?? 0);
        bucket.count += 1;
        vendorRatings.set(key, bucket);
    }

    const recommendations = items
        .map((item) => {
            const vendor = item.menus?.vendors ?? null;
            if (!vendor || vendor.status !== 'approved') {
                return null;
            }

            const vendorRatingBucket = vendorRatings.get(vendor.id);
            const vendorRating = vendorRatingBucket && vendorRatingBucket.count > 0
                ? (vendorRatingBucket.total / vendorRatingBucket.count)
                : 0;

            const quantityOrdered = popularityByItem.get(item.id) ?? 0;
            const recentQuantity = recentByItem.get(item.id) ?? 0;
            const price = Number(item.price ?? 0);

            const popularityScore = clamp01(quantityOrdered / 40);
            const recentScore = clamp01(recentQuantity / 20);
            const ratingScore = clamp01(vendorRating / 5);
            const affordabilityScore = clamp01(1 - Math.min(Math.max(price, 0), 500) / 500);
            const openScore = vendor.is_open ? 1 : 0;

            const score =
                (0.45 * popularityScore) +
                (0.2 * recentScore) +
                (0.2 * ratingScore) +
                (0.1 * openScore) +
                (0.05 * affordabilityScore);

            return {
                id: item.id,
                name: item.name,
                description: item.description,
                price,
                image_url: item.image_url,
                category: item.menus?.category_name ?? null,
                vendor: {
                    id: vendor.id,
                    name: vendor.name,
                    description: vendor.description ?? null,
                    image_url: vendor.image_url ?? null,
                    is_open: vendor.is_open ?? false,
                },
                recommendation: {
                    score: Number(score.toFixed(4)),
                    signals: {
                        popularity_orders: quantityOrdered,
                        recent_orders: recentQuantity,
                        vendor_rating: Number(vendorRating.toFixed(2)),
                        vendor_open: vendor.is_open ?? false,
                    },
                },
            };
        })
        .filter((item): item is NonNullable<typeof item> => item !== null)
        .sort((a, b) => b.recommendation.score - a.recommendation.score)
        .slice(0, limit);

    return reply.send(recommendations);
};
