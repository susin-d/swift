import { FastifyInstance } from 'fastify';
import {
    approveVendor,
    blockAdminUsersMany,
    blockAdminUser,
    cancelAdminOrder,
    getAdminAuditLogs,
    getAdminVendorMutationAuditLogs,
    getAdminOrders,
    getAdminSettings,
    getAdminUsers,
    getChartData,
    getDashboardSummary,
    getFinancePayouts,
    getFinanceSummary,
    getGlobalStats,
    getPendingVendors,
    rejectVendor,
    updateAdminSettings,
    updateAdminUsersRoleMany,
    updateAdminUserRole
} from '../../controllers/adminController';
import {
    getAdminDashboardStats,
    getAllVendors,
    updateVendorStatus,
    approveVendorsMany,
    rejectVendorsMany,
    getAuditLogs,
    getPayoutRecords
} from './admin.controller';
import { requireAdmin } from '../../middleware/rbac';

export const adminRoutes = async (app: FastifyInstance) => {
    app.addHook('preValidation', app.authenticate);

    // Admin app contract routes
    app.get('/stats', { preHandler: [requireAdmin] }, getGlobalStats);
    app.get('/dashboard/summary', { preHandler: [requireAdmin] }, getDashboardSummary);
    app.get('/charts', { preHandler: [requireAdmin] }, getChartData);
    app.get('/vendors/pending', { preHandler: [requireAdmin] }, getPendingVendors);
    app.patch('/vendors/:id/approve', { preHandler: [requireAdmin] }, approveVendor);
    app.patch('/vendors/:id/reject', { preHandler: [requireAdmin] }, rejectVendor);
    app.post('/vendors/approve-many', { preHandler: [requireAdmin] }, approveVendorsMany);
    app.post('/vendors/reject-many', { preHandler: [requireAdmin] }, rejectVendorsMany);
    app.get('/orders', { preHandler: [requireAdmin] }, getAdminOrders);
    app.patch('/orders/:id/cancel', { preHandler: [requireAdmin] }, cancelAdminOrder);
    app.get('/users', { preHandler: [requireAdmin] }, getAdminUsers);
    app.patch('/users/:id/block', { preHandler: [requireAdmin] }, blockAdminUser);
    app.patch('/users/:id/role', { preHandler: [requireAdmin] }, updateAdminUserRole);
    app.post('/users/block-many', { preHandler: [requireAdmin] }, blockAdminUsersMany);
    app.post('/users/role-many', { preHandler: [requireAdmin] }, updateAdminUsersRoleMany);
    app.get('/audit', { preHandler: [requireAdmin] }, getAdminAuditLogs);
    app.get('/audit/vendor-mutations', { preHandler: [requireAdmin] }, getAdminVendorMutationAuditLogs);
    app.get('/finance/summary', { preHandler: [requireAdmin] }, getFinanceSummary);
    app.get('/finance/payouts', { preHandler: [requireAdmin] }, getFinancePayouts);
    app.get('/finance/payouts/export', { preHandler: [requireAdmin] }, getPayoutRecords);
    app.get('/settings', { preHandler: [requireAdmin] }, getAdminSettings);
    app.post('/settings', { preHandler: [requireAdmin] }, updateAdminSettings);

    // Stubs retained for promo workflows pending full implementation.
    app.get('/promos', { preHandler: [requireAdmin] }, async (_request, reply) => reply.send([]));
    app.post('/promos', { preHandler: [requireAdmin] }, async (_request, reply) => reply.code(201).send({ message: 'Promo created' }));
    app.patch('/promos/:id', { preHandler: [requireAdmin] }, async (_request, reply) => reply.send({ message: 'Promo updated' }));

    // Legacy aliases kept for backward compatibility.
    app.get('/dashboard/stats', { preHandler: [requireAdmin] }, getAdminDashboardStats);
    app.get('/vendors', { preHandler: [requireAdmin] }, getAllVendors);
    app.patch('/vendors/:id/status', { preHandler: [requireAdmin] }, updateVendorStatus);
    app.get('/audit-logs', { preHandler: [requireAdmin] }, getAuditLogs);
};
