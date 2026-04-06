import { FastifyInstance } from 'fastify';
import { requireUser } from '../middleware/rbac';
import {
    addLoyaltyPoints,
    cancelSubscription,
    closeGroupOrder,
    createGroupOrder,
    createSubscription,
    generateReferralCode,
    getGroupOrder,
    getLoyaltyTier,
    getMyRefunds,
    getReferralByCode,
    getSubscriptionEntitlements,
    getSpendingAnalytics,
    getSubscriptions,
    getVendorSpendingAnalytics,
    joinGroupOrder,
    leaveGroupOrder,
    listRefundsAdmin,
    redeemReferralCode,
    renewSubscription,
    requestRefund,
    splitOrderAmount,
    unwatchVendor,
    updateRefundStatusAdmin,
    watchVendor,
} from '../controllers/growthController';
import { requireAdmin } from '../middleware/rbac';

export const growthRoutes = async (app: FastifyInstance) => {
    app.addHook('preValidation', app.authenticate);

    app.get('/analytics/spending', { preHandler: [requireUser] }, getSpendingAnalytics as any);
    app.get('/analytics/vendors', { preHandler: [requireUser] }, getVendorSpendingAnalytics as any);

    app.post('/referrals/generate', { preHandler: [requireUser] }, generateReferralCode as any);
    app.get('/referrals/code/:code', { preHandler: [requireUser] }, getReferralByCode as any);
    app.post('/referrals/redeem', { preHandler: [requireUser] }, redeemReferralCode as any);

    app.get('/loyalty/tier', { preHandler: [requireUser] }, getLoyaltyTier as any);
    app.post('/loyalty/points', { preHandler: [requireAdmin] }, addLoyaltyPoints as any);

    app.get('/subscriptions', { preHandler: [requireUser] }, getSubscriptions as any);
    app.post('/subscriptions/create', { preHandler: [requireAdmin] }, createSubscription as any);
    app.patch('/subscriptions/:id/cancel', { preHandler: [requireUser] }, cancelSubscription as any);
    app.patch('/subscriptions/:id/renew', { preHandler: [requireAdmin] }, renewSubscription as any);
    app.get('/subscriptions/entitlements', { preHandler: [requireUser] }, getSubscriptionEntitlements as any);

    app.post('/vendors/:id/watch', { preHandler: [requireUser] }, watchVendor as any);
    app.delete('/vendors/:id/watch', { preHandler: [requireUser] }, unwatchVendor as any);

    app.post('/orders/group', { preHandler: [requireUser] }, createGroupOrder as any);
    app.get('/orders/:id/group', { preHandler: [requireUser] }, getGroupOrder as any);
    app.post('/orders/:id/group/join', { preHandler: [requireUser] }, joinGroupOrder as any);
    app.post('/orders/:id/group/leave', { preHandler: [requireUser] }, leaveGroupOrder as any);
    app.post('/orders/:id/group/close', { preHandler: [requireUser] }, closeGroupOrder as any);
    app.patch('/orders/:id/split', { preHandler: [requireUser] }, splitOrderAmount as any);

    app.post('/orders/:id/refund', { preHandler: [requireUser] }, requestRefund as any);
    app.get('/refunds/me', { preHandler: [requireUser] }, getMyRefunds as any);
    app.get('/refunds/admin', { preHandler: [requireAdmin] }, listRefundsAdmin as any);
    app.patch('/refunds/:id/status', { preHandler: [requireAdmin] }, updateRefundStatusAdmin as any);
};
