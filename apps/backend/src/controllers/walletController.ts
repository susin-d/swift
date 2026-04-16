import { FastifyReply, FastifyRequest } from 'fastify';
import { supabase } from '../services/supabase';
import { razorpay } from '../services/razorpay';
import crypto from 'crypto';
import { buildPaginationMeta, parsePagination } from '../utils/pagination';

const userFromRequest = (request: FastifyRequest) => request.user as { sub: string; role: string } | undefined;

const toAmount = (value: unknown) => Number(Number(value || 0).toFixed(2));

export const getWalletBalance = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = userFromRequest(request);
    if (!user?.sub) {
        return reply.code(401).send({ error: 'Unauthorized', message: 'Authentication required' });
    }

    const { data, error } = await supabase
        .from('users')
        .select('wallet_balance')
        .eq('id', user.sub)
        .maybeSingle();

    if (error) throw error;
    return reply.send({
        balance: toAmount((data as any)?.wallet_balance),
        currency: 'INR',
    });
};

export const topupWallet = async (
    request: FastifyRequest<{
        Body: {
            amount?: number;
            source?: string;
            reference?: string;
            idempotencyKey?: string;
            status?: 'pending' | 'completed' | 'failed';
            userId?: string;
        };
    }>,
    reply: FastifyReply,
) => {
    const user = userFromRequest(request);
    if (!user?.sub) {
        return reply.code(401).send({ error: 'Unauthorized', message: 'Authentication required' });
    }

    const amount = toAmount(request.body?.amount);
    const status = request.body?.status || 'pending';
    const idempotencyKey = String(request.body?.idempotencyKey || '').trim() || null;
    if (!Number.isFinite(amount) || amount <= 0) {
        return reply.code(400).send({ error: 'ValidationError', message: 'Top-up amount must be greater than 0' });
    }
    if (!['pending', 'completed', 'failed'].includes(status)) {
        return reply.code(400).send({ error: 'ValidationError', message: 'Top-up status is invalid' });
    }
    if (status !== 'pending' && user.role !== 'admin') {
        return reply.code(403).send({
            error: 'Forbidden',
            message: 'Only admins can mark wallet top-ups as completed or failed',
        });
    }
    const targetUserId = user.role === 'admin'
        ? String(request.body?.userId || '').trim() || user.sub
        : user.sub;

    if (idempotencyKey) {
        const { data: existingTx, error: existingTxError } = await supabase
            .from('wallet_transactions')
            .select('*')
            .eq('user_id', targetUserId)
            .eq('idempotency_key', idempotencyKey)
            .maybeSingle();
        if (existingTxError) throw existingTxError;
        if (existingTx) {
            const { data: walletData, error: walletError } = await supabase
                .from('users')
                .select('wallet_balance')
                .eq('id', targetUserId)
                .maybeSingle();
            if (walletError) throw walletError;
            return reply.send({
                balance: toAmount((walletData as any)?.wallet_balance),
                currency: 'INR',
                transaction: existingTx,
                replayed: true,
            });
        }
    }

    const { data: userData, error: userError } = await supabase
        .from('users')
        .select('wallet_balance')
        .eq('id', targetUserId)
        .maybeSingle();

    if (userError) throw userError;

    const previousBalance = toAmount((userData as any)?.wallet_balance);
    const nextBalance = user.role === 'admin' && status === 'completed'
        ? toAmount(previousBalance + amount)
        : previousBalance;
    const now = new Date().toISOString();

    const operations = [];
    if (user.role === 'admin' && status === 'completed') {
        operations.push(supabase.from('users').update({ wallet_balance: nextBalance }).eq('id', targetUserId));
    }
    operations.push(
        supabase
            .from('wallet_transactions')
            .insert({
                user_id: targetUserId,
                amount,
                transaction_type: 'topup',
                status,
                source: request.body?.source || 'manual',
                reference: request.body?.reference || null,
                idempotency_key: idempotencyKey,
                metadata: { previous_balance: previousBalance, next_balance: nextBalance },
                created_at: now,
            })
            .select('*')
            .single(),
    );

    const results = await Promise.all(operations as any[]);
    if (status === 'completed') {
        const updateResult = results[0] as { error?: unknown };
        if (updateResult.error) throw updateResult.error;
    }
    const txResult = (results[results.length - 1] || {}) as { data?: unknown; error?: unknown };
    if (txResult.error) throw txResult.error;
    const transaction = txResult.data;

    return reply.send({
        balance: nextBalance,
        currency: 'INR',
        transaction,
    });
};

export const getWalletTransactions = async (
    request: FastifyRequest<{ Querystring: { page?: string | number; limit?: string | number } }>,
    reply: FastifyReply,
) => {
    const user = userFromRequest(request);
    if (!user?.sub) {
        return reply.code(401).send({ error: 'Unauthorized', message: 'Authentication required' });
    }

    const { page, limit, from, to } = parsePagination(request.query || {}, { defaultLimit: 20, maxLimit: 100 });
    const [{ count, error: countError }, { data, error: dataError }] = await Promise.all([
        supabase
            .from('wallet_transactions')
            .select('*', { count: 'exact', head: true })
            .eq('user_id', user.sub),
        supabase
            .from('wallet_transactions')
            .select('*')
            .eq('user_id', user.sub)
            .order('created_at', { ascending: false })
            .range(from, to),
    ]);

    if (countError) throw countError;
    if (dataError) throw dataError;

    const total = count || 0;
    return reply.send({
        transactions: data || [],
        page,
        limit,
        total,
        meta: buildPaginationMeta(page, limit, total),
    });
};

export const createTopupPayment = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = userFromRequest(request);
    const { amount, currency = 'INR' } = request.body as any;

    if (!user?.sub) {
        return reply.code(401).send({ error: 'Unauthorized' });
    }

    if (!amount || amount <= 0) {
        return reply.code(400).send({ error: 'Amount must be greater than zero' });
    }

    try {
        const amountPaise = Math.round(Number(amount) * 100);
        const options = {
            amount: amountPaise,
            currency,
            receipt: `topup_${Date.now()}_${user.sub.substring(0, 8)}`,
        };

        const gatewayOrder = await razorpay.orders.create(options);
        const keyId = (process.env.RAZORPAY_KEY_ID || '').trim();

        return reply.send({
            ...gatewayOrder,
            key: keyId,
            user_id: user.sub,
        });
    } catch (error: any) {
        return reply.code(500).send({ error: error.message });
    }
};

export const verifyAndCompleteTopup = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = userFromRequest(request);
    const {
        razorpay_order_id,
        razorpay_payment_id,
        razorpay_signature,
        amount,
    } = request.body as any;

    if (!user?.sub) {
        return reply.code(401).send({ error: 'Unauthorized' });
    }

    // 1. Verify Signature
    const secret = (process.env.RAZORPAY_KEY_SECRET || '').trim();
    const generated_signature = crypto
        .createHmac('sha256', secret)
        .update(`${razorpay_order_id}|${razorpay_payment_id}`)
        .digest('hex');

    if (generated_signature !== razorpay_signature) {
        return reply.code(400).send({ error: 'Invalid signature' });
    }

    // 2. Atomically update balance and create transaction
    try {
        const topupAmount = toAmount(amount);
        
        const { data: userData, error: userError } = await supabase
            .from('users')
            .select('wallet_balance')
            .eq('id', user.sub)
            .single();

        if (userError) throw userError;

        const previousBalance = toAmount((userData as any)?.wallet_balance);
        const nextBalance = toAmount(previousBalance + topupAmount);

        const { error: updateError } = await supabase
            .from('users')
            .update({ wallet_balance: nextBalance })
            .eq('id', user.sub);

        if (updateError) throw updateError;

        const { data: transaction, error: txError } = await supabase
            .from('wallet_transactions')
            .insert({
                user_id: user.sub,
                amount: topupAmount,
                transaction_type: 'topup',
                status: 'completed',
                source: 'razorpay',
                reference: razorpay_payment_id,
                metadata: {
                    razorpay_order_id,
                    previous_balance: previousBalance,
                    next_balance: nextBalance
                }
            })
            .select()
            .single();

        if (txError) {
            await supabase.from('users').update({ wallet_balance: previousBalance }).eq('id', user.sub);
            throw txError;
        }

        return reply.send({
            status: 'success',
            balance: nextBalance,
            transaction
        });
    } catch (error: any) {
        return reply.code(500).send({ error: error.message });
    }
};
