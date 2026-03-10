import { FastifyRequest, FastifyReply } from 'fastify';
import { razorpay } from '../services/razorpay';
import crypto from 'crypto';

export const createRazorpayOrder = async (request: FastifyRequest, reply: FastifyReply) => {
    const { amount, currency = 'INR' } = request.body as any;

    try {
        const options = {
            amount: Math.round(amount * 100), // Razorpay expects amount in paise
            currency,
            receipt: `receipt_${Date.now()}`,
        };

        const order = await razorpay.orders.create(options);
        return reply.send(order);
    } catch (error: any) {
        return reply.code(400).send({ error: error.message });
    }
};

export const verifyPayment = async (request: FastifyRequest, reply: FastifyReply) => {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = request.body as any;

    const secret = process.env.RAZORPAY_KEY_SECRET || '';
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
