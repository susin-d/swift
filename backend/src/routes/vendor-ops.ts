import { FastifyInstance } from 'fastify';
import { updateVendorProfile, getMyVendorProfile, getVendorStats } from '../controllers/vendorController';
import { getMyVendorMenu } from '../controllers/menuController';
import { getVendorOrders } from '../controllers/orderController';
import { requireVendor } from '../middleware/rbac';

export const vendorOpsRoutes = async (app: FastifyInstance) => {
    app.addHook('preValidation', app.authenticate);

    app.get('/profile', { preHandler: [requireVendor] }, getMyVendorProfile);
    app.patch('/profile', { preHandler: [requireVendor] }, updateVendorProfile);
    app.get('/menu', { preHandler: [requireVendor] }, getMyVendorMenu);
    app.get('/orders', { preHandler: [requireVendor] }, getVendorOrders);
    app.get('/stats', { preHandler: [requireVendor] }, getVendorStats);
};
