import { FastifyReply, FastifyRequest } from 'fastify';
import { supabase } from '../services/supabase';

const isCartTableMissing = (error: any) => {
  if (!error) return false;
  const code = String(error.code ?? '');
  const message = String(error.message ?? '').toLowerCase();
  return code === 'PGRST205'
    || code === '42P01'
    || (message.includes('user_carts') && message.includes('schema cache'))
    || (message.includes('relation') && message.includes('user_carts') && message.includes('does not exist'));
};

type CartItemPayload = {
  item: Record<string, unknown>;
  quantity: number;
};

const normalizeCartItems = (raw: unknown): CartItemPayload[] => {
  if (!Array.isArray(raw)) return [];

  const normalized: CartItemPayload[] = [];
  for (const finalEntry of raw) {
    if (typeof finalEntry !== 'object' || finalEntry === null) continue;

    const entry = finalEntry as Record<string, unknown>;
    const itemRaw = entry['item'];
    const quantityRaw = entry['quantity'];

    if (typeof itemRaw !== 'object' || itemRaw === null) continue;
    if (typeof quantityRaw !== 'number' || !Number.isFinite(quantityRaw)) continue;

    const quantity = Math.floor(quantityRaw);
    if (quantity <= 0) continue;

    const item = itemRaw as Record<string, unknown>;
    const itemId = typeof item['id'] === 'string' ? item['id'].trim() : '';
    if (!itemId) continue;

    normalized.push({
      item: {
        id: itemId,
        menu_id: item['menu_id'],
        vendor_id: item['vendor_id'],
        name: item['name'],
        description: item['description'],
        price: item['price'],
        is_available: item['is_available'],
        image_url: item['image_url'],
        category: item['category'],
      },
      quantity,
    });
  }

  return normalized;
};

export const getMyCart = async (request: FastifyRequest, reply: FastifyReply) => {
  const user = request.user as any;

  const { data, error } = await supabase
    .from('user_carts')
    .select('items')
    .eq('user_id', user.sub)
    .maybeSingle();

  if (error) {
    if (isCartTableMissing(error)) {
      return reply.send({ items: [] });
    }
    throw error;
  }

  const items = normalizeCartItems(data?.items);
  return reply.send({ items });
};

export const setMyCart = async (request: FastifyRequest, reply: FastifyReply) => {
  const user = request.user as any;
  const body = request.body as { items?: unknown };

  if (!Array.isArray(body?.items)) {
    const err = new Error('items array is required') as any;
    err.statusCode = 400;
    throw err;
  }

  const items = normalizeCartItems(body.items);

  const { data, error } = await supabase
    .from('user_carts')
    .upsert(
      {
        user_id: user.sub,
        items,
        updated_at: new Date().toISOString(),
      },
      { onConflict: 'user_id' },
    )
    .select('items')
    .single();

  if (error) {
    if (isCartTableMissing(error)) {
      const err = new Error('Cart storage is not configured yet') as any;
      err.statusCode = 503;
      throw err;
    }
    throw error;
  }

  return reply.send({ items: normalizeCartItems(data?.items) });
};
