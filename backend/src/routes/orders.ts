import { FastifyInstance } from 'fastify';
import { createOrder, getMyOrders, updateOrderStatus, cancelUserOrder, getOrderSlots, updateOrderHandoff } from '../controllers/orderController';
import { requireUser, requireVendor } from '../middleware/rbac';

export const orderRoutes = async (app: FastifyInstance) => {
    app.addHook('preValidation', app.authenticate);

    app.post('/', { preHandler: [requireUser] }, createOrder);
    app.get('/slots', { preHandler: [requireUser] }, getOrderSlots);
    app.get('/me', { preHandler: [requireUser] }, getMyOrders);
    app.patch('/:id/cancel', { preHandler: [requireUser] }, cancelUserOrder);

    app.patch('/:id/status', { preHandler: [requireVendor] }, updateOrderStatus);
    app.patch('/:id/handoff', { preHandler: [requireVendor] }, updateOrderHandoff);
};
