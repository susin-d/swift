import { FastifyInstance } from 'fastify';
import { getGlobalStats, getChartData, getPendingVendors, approveVendor, updateUserRole, createVendorAccount } from '../controllers/adminController';
import { requireAdmin } from '../middleware/rbac';

export const adminRoutes = async (app: FastifyInstance) => {
    app.addHook('preValidation', app.authenticate);
    app.addHook('preHandler', requireAdmin);

    app.get('/stats', getGlobalStats);
    app.get('/charts', getChartData);
    app.get('/vendors/pending', getPendingVendors);
    app.patch('/vendors/:id/approve', approveVendor);
    app.post('/users/role', updateUserRole);
    app.post('/vendors', createVendorAccount);
};
