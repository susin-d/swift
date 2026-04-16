import { FastifyRequest, FastifyReply } from 'fastify';
import { razorpay } from '../services/razorpay';
import { supabase } from '../services/supabase';
import crypto from 'crypto';

export const createRazorpayOrder = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as any;
    const { order_id, currency = 'INR' } = request.body as any;
    if (!order_id || typeof order_id !== 'string') {
        return reply.code(400).send({ error: 'order_id is required' });
    }

    try {
        const { data: order, error: orderError } = await supabase
            .from('orders')
            .select('id, user_id, total_amount, status')
            .eq('id', order_id)
            .maybeSingle();

        if (orderError) throw orderError;
        if (!order) {
            return reply.code(404).send({ error: 'Order not found' });
        }

        const role = String(user?.role || '').toLowerCase();
        const isAdmin = role === 'admin';
        if (!isAdmin && order.user_id !== user?.sub) {
            return reply.code(403).send({ error: 'Forbidden' });
        }

        const normalizedStatus = String(order.status || '').toLowerCase();
        if (['cancelled'].includes(normalizedStatus)) {
            return reply.code(409).send({ error: 'Cannot create payment order for cancelled order' });
        }

        const amountPaise = Math.round(Number(order.total_amount || 0) * 100);
        if (!Number.isFinite(amountPaise) || amountPaise <= 0) {
            return reply.code(400).send({ error: 'Order amount must be greater than zero' });
        }

        const options = {
            amount: amountPaise, // Razorpay expects amount in paise
            currency,
            receipt: `receipt_${Date.now()}`,
        };

        const gatewayOrder = await razorpay.orders.create(options);
        // Attach public key to response
        const keyId = (process.env.RAZORPAY_KEY_ID || '').trim();
        return reply.send({ ...gatewayOrder, key: keyId, backend_order_id: order.id });
    } catch (error: any) {
        return reply.code(400).send({ error: error.message });
    }
};

export const verifyPayment = async (request: FastifyRequest, reply: FastifyReply) => {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = request.body as any;

    const secret = (process.env.RAZORPAY_KEY_SECRET || '').trim();
    const generated_signature = crypto
        .createHmac('sha256', secret)
        .update(`${razorpay_order_id}|${razorpay_payment_id}`)
        .digest('hex');

    if (generated_signature === razorpay_signature) {
        return reply.send({ status: 'success', message: 'Payment verified' });
    } else {
        return reply.code(400).send({ status: 'failure', message: 'Signature mismatch' });
    }
};
