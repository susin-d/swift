import { FastifyInstance } from 'fastify';
import { createRazorpayOrder, verifyPayment } from '../controllers/paymentController';

export const paymentRoutes = async (app: FastifyInstance) => {
    app.addHook('preValidation', app.authenticate);

    app.post('/create-order', createRazorpayOrder);
    app.post('/verify', verifyPayment);
};
