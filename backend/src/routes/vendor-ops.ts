import { FastifyInstance } from 'fastify';
import {
    updateVendorProfile,
    getMyVendorProfile,
    getVendorStats,
    getVendorStoreControls,
    updateVendorStoreControls,
    getVendorFinanceEarnings,
    getVendorFinancePayouts,
    getVendorFinanceTransactions,
    getVendorFinanceTaxReports,
    getVendorAnalyticsSales,
    getVendorAnalyticsPerformance,
    getVendorAnalyticsPeakHours,
    getVendorAnalyticsTopItems,
    getVendorStaffManagement,
    getVendorStaffRoles,
    createVendorStaffMember,
    updateVendorStaffMember,
    deleteVendorStaffMember,
    getVendorStaffInvitations,
    createVendorStaffInvitation,
    updateVendorStaffRoles,
    getVendorReportsDownload,
    getVendorReportsSales,
    getVendorReportsOrders,
    getVendorPreferencesLanguage,
    getVendorPreferencesTheme,
    getVendorPreferencesApp,
    updateVendorPreferencesLanguage,
    updateVendorPreferencesTheme,
    updateVendorPreferencesApp,
} from '../controllers/vendorController';
import { getMyVendorMenu, uploadMenuItemImageEndpoint } from '../controllers/menuController';
import {
    acceptVendorOrder,
    getVendorActiveOrders,
    getVendorOrderById,
    getVendorOrders,
    rejectVendorOrder,
    streamVendorOrderEvents,
    updateVendorOrderStatusAction,
} from '../controllers/orderController';
import { requireVendor } from '../middleware/rbac';

export const vendorOpsRoutes = async (app: FastifyInstance) => {
    app.addHook('preValidation', app.authenticate);

    app.get('/profile', { preHandler: [requireVendor] }, getMyVendorProfile);
    app.patch('/profile', { preHandler: [requireVendor] }, updateVendorProfile);
    app.get('/menu', { preHandler: [requireVendor] }, getMyVendorMenu);
    app.post('/menu/upload-image', { preHandler: [requireVendor] }, uploadMenuItemImageEndpoint);
    app.get('/orders', { preHandler: [requireVendor] }, getVendorOrders);
    app.get('/orders/active', { preHandler: [requireVendor] }, getVendorActiveOrders);
    app.get('/orders/:id', { preHandler: [requireVendor] }, getVendorOrderById);
    app.post('/orders/:id/accept', { preHandler: [requireVendor] }, acceptVendorOrder);
    app.post('/orders/:id/reject', { preHandler: [requireVendor] }, rejectVendorOrder);
    app.post('/orders/:id/status', { preHandler: [requireVendor] }, updateVendorOrderStatusAction);
    app.get('/orders/stream', { preHandler: [requireVendor] }, streamVendorOrderEvents);
    app.get('/store-controls', { preHandler: [requireVendor] }, getVendorStoreControls);
    app.patch('/store-controls', { preHandler: [requireVendor] }, updateVendorStoreControls);
    app.get('/finance/earnings', { preHandler: [requireVendor] }, getVendorFinanceEarnings);
    app.get('/finance/payouts', { preHandler: [requireVendor] }, getVendorFinancePayouts);
    app.get('/finance/transactions', { preHandler: [requireVendor] }, getVendorFinanceTransactions);
    app.get('/finance/tax-reports', { preHandler: [requireVendor] }, getVendorFinanceTaxReports);
    app.get('/analytics/sales', { preHandler: [requireVendor] }, getVendorAnalyticsSales);
    app.get('/analytics/performance', { preHandler: [requireVendor] }, getVendorAnalyticsPerformance);
    app.get('/analytics/peak-hours', { preHandler: [requireVendor] }, getVendorAnalyticsPeakHours);
    app.get('/analytics/top-items', { preHandler: [requireVendor] }, getVendorAnalyticsTopItems);
    app.get('/staff/management', { preHandler: [requireVendor] }, getVendorStaffManagement);
    app.post('/staff/management', { preHandler: [requireVendor] }, createVendorStaffMember);
    app.patch('/staff/management/:staffId', { preHandler: [requireVendor] }, updateVendorStaffMember);
    app.delete('/staff/management/:staffId', { preHandler: [requireVendor] }, deleteVendorStaffMember);
    app.get('/staff/invitations', { preHandler: [requireVendor] }, getVendorStaffInvitations);
    app.post('/staff/invitations', { preHandler: [requireVendor] }, createVendorStaffInvitation);
    app.get('/staff/roles', { preHandler: [requireVendor] }, getVendorStaffRoles);
    app.patch('/staff/roles', { preHandler: [requireVendor] }, updateVendorStaffRoles);
    app.get('/reports/download', { preHandler: [requireVendor] }, getVendorReportsDownload);
    app.get('/reports/sales', { preHandler: [requireVendor] }, getVendorReportsSales);
    app.get('/reports/orders', { preHandler: [requireVendor] }, getVendorReportsOrders);
    app.get('/preferences/language', { preHandler: [requireVendor] }, getVendorPreferencesLanguage);
    app.patch('/preferences/language', { preHandler: [requireVendor] }, updateVendorPreferencesLanguage);
    app.get('/preferences/theme', { preHandler: [requireVendor] }, getVendorPreferencesTheme);
    app.patch('/preferences/theme', { preHandler: [requireVendor] }, updateVendorPreferencesTheme);
    app.get('/preferences/app', { preHandler: [requireVendor] }, getVendorPreferencesApp);
    app.patch('/preferences/app', { preHandler: [requireVendor] }, updateVendorPreferencesApp);
    app.get('/stats', { preHandler: [requireVendor] }, getVendorStats);
};
