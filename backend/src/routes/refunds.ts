import { FastifyInstance } from 'fastify';
import { requireUser, requireAdmin } from '../middleware/rbac';
import { requestRefund, getMyRefunds, getAdminRefunds, resolveRefund } from '../controllers/refundController';

export const refundRoutes = async (app: FastifyInstance) => {
    app.addHook('preValidation', app.authenticate);
    app.post('/orders/:id/refund', { preHandler: [requireUser] }, requestRefund);
    app.get('/refunds/me', { preHandler: [requireUser] }, getMyRefunds);
    app.get('/admin/refunds', { preHandler: [requireAdmin] }, getAdminRefunds);
    app.patch('/admin/refunds/:id', { preHandler: [requireAdmin] }, resolveRefund);
};
