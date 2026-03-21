import { FastifyInstance } from 'fastify';
import {
    getAdminDashboardStats,
    getAllVendors,
    updateVendorStatus,
    getAuditLogs,
    getAllOrders,
    cancelOrder,
    blockUser,
    getPayoutRecords
} from './admin.controller';
import { requireAdmin } from '../../middleware/rbac';

export const adminRoutes = async (app: FastifyInstance) => {
    app.addHook('preValidation', app.authenticate);

    // Contract aliases
    app.get('/stats', { preHandler: [requireAdmin] }, getAdminDashboardStats);
    app.get('/vendors/pending', { preHandler: [requireAdmin] }, async (request, reply) => {
        (request.query as any) = { ...(request.query as any), status: 'pending' };
        return getAllVendors(request, reply);
    });
    app.patch('/vendors/:id/reject', { preHandler: [requireAdmin] }, async (request, reply) => {
        (request.body as any) = { ...(request.body as any), status: 'rejected' };
        return updateVendorStatus(request, reply);
    });
    app.get('/users', { preHandler: [requireAdmin] }, async (_request, reply) => reply.send([]));
    app.get('/audit', { preHandler: [requireAdmin] }, getAuditLogs);
    app.get('/finance/payouts/export', { preHandler: [requireAdmin] }, getPayoutRecords);
    app.get('/promos', { preHandler: [requireAdmin] }, async (_request, reply) => reply.send([]));
    app.post('/promos', { preHandler: [requireAdmin] }, async (_request, reply) => reply.code(201).send({ message: 'Promo created' }));
    app.patch('/promos/:id', { preHandler: [requireAdmin] }, async (_request, reply) => reply.send({ message: 'Promo updated' }));

    app.get('/dashboard/stats', { preHandler: [requireAdmin] }, getAdminDashboardStats);
    app.get('/vendors', { preHandler: [requireAdmin] }, getAllVendors);
    app.patch('/vendors/:id/status', { preHandler: [requireAdmin] }, updateVendorStatus);
    app.get('/audit-logs', { preHandler: [requireAdmin] }, getAuditLogs);
    app.get('/orders', { preHandler: [requireAdmin] }, getAllOrders);
    app.patch('/orders/:id/cancel', { preHandler: [requireAdmin] }, cancelOrder);
    app.patch('/users/:id/block', { preHandler: [requireAdmin] }, blockUser);
    app.get('/finance/payouts', { preHandler: [requireAdmin] }, getPayoutRecords);
};
