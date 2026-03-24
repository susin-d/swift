import { FastifyInstance } from 'fastify';
import { updateVendorProfile, getMyVendorProfile, getVendorStats } from '../controllers/vendorController';
import { getMyVendorMenu } from '../controllers/menuController';
import {
    acceptVendorOrder,
    getVendorActiveOrders,
    getVendorOrderById,
    getVendorOrders,
    rejectVendorOrder,
    updateVendorOrderStatusAction,
} from '../controllers/orderController';
import { requireVendor } from '../middleware/rbac';

export const vendorOpsRoutes = async (app: FastifyInstance) => {
    app.addHook('preValidation', app.authenticate);

    app.get('/profile', { preHandler: [requireVendor] }, getMyVendorProfile);
    app.patch('/profile', { preHandler: [requireVendor] }, updateVendorProfile);
    app.get('/menu', { preHandler: [requireVendor] }, getMyVendorMenu);
    app.get('/orders', { preHandler: [requireVendor] }, getVendorOrders);
    app.get('/orders/active', { preHandler: [requireVendor] }, getVendorActiveOrders);
    app.get('/orders/:id', { preHandler: [requireVendor] }, getVendorOrderById);
    app.post('/orders/:id/accept', { preHandler: [requireVendor] }, acceptVendorOrder);
    app.post('/orders/:id/reject', { preHandler: [requireVendor] }, rejectVendorOrder);
    app.post('/orders/:id/status', { preHandler: [requireVendor] }, updateVendorOrderStatusAction);
    app.get('/stats', { preHandler: [requireVendor] }, getVendorStats);
};
