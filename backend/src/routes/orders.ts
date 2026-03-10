import { FastifyInstance } from 'fastify';
import { createOrder, getMyOrders, updateOrderStatus } from '../controllers/orderController';
import { requireVendor } from '../middleware/rbac';

export const orderRoutes = async (app: FastifyInstance) => {
    app.addHook('preValidation', app.authenticate);

    app.post('/', createOrder);
    app.get('/me', getMyOrders);

    app.patch('/:id/status', { preHandler: [requireVendor] }, updateOrderStatus);
};
