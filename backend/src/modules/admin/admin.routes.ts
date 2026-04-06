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
import { createPromo, getAdminPromos, updatePromo } from '../../controllers/promoController';
import { getAdminSupportSummary, listAdminSupportTickets, updateAdminSupportTicket } from '../../controllers/chatController';
import { listDeletionReminders, processDueDeletionRequests } from '../../controllers/userAccountController';

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

    // Admin promo management routes.
    app.get('/promos', { preHandler: [requireAdmin] }, getAdminPromos as any);
    app.post('/promos', { preHandler: [requireAdmin] }, createPromo as any);
    app.patch('/promos/:id', { preHandler: [requireAdmin] }, updatePromo as any);

    // Admin support inbox routes.
    app.get('/support/tickets', { preHandler: [requireAdmin] }, listAdminSupportTickets as any);
    app.get('/support/summary', { preHandler: [requireAdmin] }, getAdminSupportSummary as any);
    app.patch('/support/tickets/:id', { preHandler: [requireAdmin] }, updateAdminSupportTicket as any);
    app.post('/users/deletions/process-due', { preHandler: [requireAdmin] }, processDueDeletionRequests as any);
    app.get('/users/deletions/reminders', { preHandler: [requireAdmin] }, listDeletionReminders as any);

    // Legacy aliases kept for backward compatibility.
    app.get('/dashboard/stats', { preHandler: [requireAdmin] }, getAdminDashboardStats);
    app.get('/vendors', { preHandler: [requireAdmin] }, getAllVendors);
    app.patch('/vendors/:id/status', { preHandler: [requireAdmin] }, updateVendorStatus);
    app.get('/audit-logs', { preHandler: [requireAdmin] }, getAuditLogs);
};
