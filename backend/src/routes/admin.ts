import { FastifyInstance } from 'fastify';
import {
    approveVendor,
    blockAdminUser,
    cancelAdminOrder,
    createVendorAccount,
    getAdminAuditLogs,
    getAdminOrders,
    getAdminSettings,
    getAdminUsers,
    getChartData,
    getDashboardSummary,
    getFinancePayouts,
    exportFinancePayouts,
    getFinanceSummary,
    getGlobalStats,
    getPendingVendors,
    rejectVendor,
    updateAdminSettings,
    updateAdminUserRole,
    updateUserRole,
} from '../controllers/adminController';
import { createPromo, getAdminPromos, updatePromo } from '../controllers/promoController';
import { requireAdmin } from '../middleware/rbac';

export const adminRoutes = async (app: FastifyInstance) => {
    app.addHook('preValidation', app.authenticate);
    app.addHook('preHandler', requireAdmin);

    app.get('/stats', getGlobalStats);
    app.get('/dashboard/summary', getDashboardSummary);
    app.get('/charts', getChartData);
    app.get('/finance/summary', getFinanceSummary);
    app.get('/finance/payouts', getFinancePayouts);
    app.get('/finance/payouts/export', exportFinancePayouts);
    app.get('/promos', getAdminPromos);
    app.post('/promos', createPromo);
    app.patch('/promos/:id', updatePromo);
    app.get('/audit', getAdminAuditLogs);
    app.get('/settings', getAdminSettings);
    app.post('/settings', updateAdminSettings);
    app.get('/orders', getAdminOrders);
    app.patch('/orders/:id/cancel', cancelAdminOrder);
    app.get('/users', getAdminUsers);
    app.patch('/users/:id/block', blockAdminUser);
    app.patch('/users/:id/role', updateAdminUserRole);
    app.get('/vendors/pending', getPendingVendors);
    app.patch('/vendors/:id/approve', approveVendor);
    app.patch('/vendors/:id/reject', rejectVendor);
    app.post('/users/role', updateUserRole);
    app.post('/vendors', createVendorAccount);
};
