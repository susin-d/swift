import { FastifyRequest, FastifyReply } from 'fastify';
import { supabase } from '../services/supabase';

export const getWalletBalance = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    // Upsert wallet if missing
    const { data: wallet, error } = await supabase
        .from('wallets')
        .upsert({ user_id: user.sub, updated_at: new Date().toISOString() }, { onConflict: 'user_id', ignoreDuplicates: false })
        .select('balance, currency, user_id')
        .single();
    if (error) throw error;
    return reply.send(wallet);
};

export const topupWallet = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const { amount } = request.body as { amount: number };
    if (!amount || amount <= 0 || amount > 10000) {
        return reply.code(400).send({ error: 'InvalidAmount', message: 'Amount must be between 1 and 10000' });
    }
    // Upsert wallet first
    await supabase.from('wallets').upsert({ user_id: user.sub, updated_at: new Date().toISOString() }, { onConflict: 'user_id', ignoreDuplicates: false });
    // Increment balance
    const { data: current } = await supabase.from('wallets').select('balance').eq('user_id', user.sub).single();
    const newBalance = Number(current?.balance ?? 0) + Number(amount);
    const { data: wallet, error } = await supabase
        .from('wallets')
        .update({ balance: newBalance, updated_at: new Date().toISOString() })
        .eq('user_id', user.sub)
        .select('balance, currency, user_id')
        .single();
    if (error) throw error;
    // Insert transaction
    await supabase.from('wallet_transactions').insert({ wallet_user_id: user.sub, type: 'topup', amount: Number(amount) });
    return reply.send(wallet);
};

export const getWalletTransactions = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const query = request.query as { page?: string; per_page?: string };
    const page = Math.max(1, parseInt(query.page ?? '1', 10));
    const perPage = Math.min(100, Math.max(1, parseInt(query.per_page ?? '20', 10)));
    const from = (page - 1) * perPage;
    const to = from + perPage - 1;
    const { data, error, count } = await supabase
        .from('wallet_transactions')
        .select('*', { count: 'exact' })
        .eq('wallet_user_id', user.sub)
        .order('created_at', { ascending: false })
        .range(from, to);
    if (error) throw error;
    return reply.send({ transactions: data ?? [], meta: { total: count ?? 0, page, per_page: perPage } });
};

export const debitWallet = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const { amount, reference } = request.body as { amount: number; reference?: string };
    if (!amount || amount <= 0) {
        return reply.code(400).send({ error: 'InvalidAmount', message: 'Amount must be greater than 0' });
    }
    const { data: current } = await supabase.from('wallets').select('balance').eq('user_id', user.sub).single();
    const currentBalance = Number(current?.balance ?? 0);
    if (currentBalance < Number(amount)) {
        return reply.code(400).send({ error: 'InsufficientBalance', message: 'Insufficient wallet balance' });
    }
    const newBalance = currentBalance - Number(amount);
    const { data: wallet, error } = await supabase
        .from('wallets')
        .update({ balance: newBalance, updated_at: new Date().toISOString() })
        .eq('user_id', user.sub)
        .select('balance, currency, user_id')
        .single();
    if (error) throw error;
    await supabase.from('wallet_transactions').insert({ wallet_user_id: user.sub, type: 'debit', amount: Number(amount), reference: reference ?? null });
    return reply.send(wallet);
};
