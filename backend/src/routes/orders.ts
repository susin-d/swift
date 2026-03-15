import { FastifyInstance } from 'fastify';
import { createOrder, getMyOrders, updateOrderStatus } from '../controllers/orderController';
import { requireUser, requireVendor } from '../middleware/rbac';

export const orderRoutes = async (app: FastifyInstance) => {
    app.addHook('preValidation', app.authenticate);

    app.post('/', { preHandler: [requireUser] }, createOrder);
    app.get('/me', { preHandler: [requireUser] }, getMyOrders);

    app.patch('/:id/status', { preHandler: [requireVendor] }, updateOrderStatus);
};
