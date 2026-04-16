import { FastifyInstance } from 'fastify';
import { createRazorpayOrder, verifyPayment } from '../controllers/paymentController';
import { requireUser } from '../middleware/rbac';

export const paymentRoutes = async (app: FastifyInstance) => {
    app.addHook('preValidation', app.authenticate);
    app.addHook('preHandler', requireUser);

    app.post('/create-order', createRazorpayOrder);
    app.post('/verify', verifyPayment);
};
