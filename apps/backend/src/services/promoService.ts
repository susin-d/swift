import { supabase } from './supabase';

export type DiscountType = 'percent' | 'fixed';

export const normalizePromoCode = (code: string) => code.trim().toUpperCase();

export const fetchPromoByCode = async (code: string) => {
    const normalized = normalizePromoCode(code);
    const { data, error } = await supabase
        .from('promotions')
        .select('*')
        .ilike('code', normalized)
        .single();

    if (error) {
        const err = new Error('Promo code not found') as any;
        err.statusCode = 404;
        throw err;
    }

    return data;
};

export const validatePromo = async (code: string, orderTotal: number) => {
    const promo = await fetchPromoByCode(code);
    const now = new Date();

    if (!promo.is_active) {
        const err = new Error('Promo code is inactive') as any;
        err.statusCode = 400;
        throw err;
    }

    if (promo.starts_at && new Date(promo.starts_at) > now) {
        const err = new Error('Promo code is not active yet') as any;
        err.statusCode = 400;
        throw err;
    }

    if (promo.ends_at && new Date(promo.ends_at) < now) {
        const err = new Error('Promo code has expired') as any;
        err.statusCode = 400;
        throw err;
    }

    if (promo.usage_limit && promo.usage_count >= promo.usage_limit) {
        const err = new Error('Promo code usage limit reached') as any;
        err.statusCode = 400;
        throw err;
    }

    if (orderTotal < Number(promo.min_order_amount || 0)) {
        const err = new Error('Order total is below the promo minimum') as any;
        err.statusCode = 400;
        throw err;
    }

    let discountAmount = 0;
    if (promo.discount_type === 'percent') {
        discountAmount = (orderTotal * Number(promo.discount_value)) / 100;
    } else {
        discountAmount = Number(promo.discount_value);
    }

    if (promo.max_discount_amount) {
        discountAmount = Math.min(discountAmount, Number(promo.max_discount_amount));
    }

    discountAmount = Math.min(discountAmount, orderTotal);

    return {
        promo,
        discount_amount: Number(discountAmount.toFixed(2)),
        final_amount: Number((orderTotal - discountAmount).toFixed(2)),
    };
};
