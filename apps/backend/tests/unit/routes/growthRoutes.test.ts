import { growthRoutes } from '../../../src/routes/growth';
import { requireUser } from '../../../src/middleware/rbac';
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
} from '../../../src/controllers/growthController';
import { requireAdmin } from '../../../src/middleware/rbac';

describe('growthRoutes', () => {
    it('registers growth and retention routes', async () => {
        const app: any = {
            authenticate: jest.fn(),
            addHook: jest.fn(),
            get: jest.fn(),
            post: jest.fn(),
            patch: jest.fn(),
            delete: jest.fn(),
        };

        await growthRoutes(app);

        expect(app.addHook).toHaveBeenCalledWith('preValidation', app.authenticate);
        expect(app.get).toHaveBeenCalledWith('/analytics/spending', { preHandler: [requireUser] }, getSpendingAnalytics as any);
        expect(app.get).toHaveBeenCalledWith('/analytics/vendors', { preHandler: [requireUser] }, getVendorSpendingAnalytics as any);
        expect(app.post).toHaveBeenCalledWith('/referrals/generate', { preHandler: [requireUser] }, generateReferralCode as any);
        expect(app.get).toHaveBeenCalledWith('/referrals/code/:code', { preHandler: [requireUser] }, getReferralByCode as any);
        expect(app.post).toHaveBeenCalledWith('/referrals/redeem', { preHandler: [requireUser] }, redeemReferralCode as any);
        expect(app.get).toHaveBeenCalledWith('/loyalty/tier', { preHandler: [requireUser] }, getLoyaltyTier as any);
        expect(app.post).toHaveBeenCalledWith('/loyalty/points', { preHandler: [requireAdmin] }, addLoyaltyPoints as any);
        expect(app.get).toHaveBeenCalledWith('/subscriptions', { preHandler: [requireUser] }, getSubscriptions as any);
        expect(app.post).toHaveBeenCalledWith('/subscriptions/create', { preHandler: [requireAdmin] }, createSubscription as any);
        expect(app.patch).toHaveBeenCalledWith('/subscriptions/:id/cancel', { preHandler: [requireUser] }, cancelSubscription as any);
        expect(app.patch).toHaveBeenCalledWith('/subscriptions/:id/renew', { preHandler: [requireAdmin] }, renewSubscription as any);
        expect(app.get).toHaveBeenCalledWith('/subscriptions/entitlements', { preHandler: [requireUser] }, getSubscriptionEntitlements as any);
        expect(app.post).toHaveBeenCalledWith('/vendors/:id/watch', { preHandler: [requireUser] }, watchVendor as any);
        expect(app.delete).toHaveBeenCalledWith('/vendors/:id/watch', { preHandler: [requireUser] }, unwatchVendor as any);
        expect(app.post).toHaveBeenCalledWith('/orders/group', { preHandler: [requireUser] }, createGroupOrder as any);
        expect(app.get).toHaveBeenCalledWith('/orders/:id/group', { preHandler: [requireUser] }, getGroupOrder as any);
        expect(app.post).toHaveBeenCalledWith('/orders/:id/group/join', { preHandler: [requireUser] }, joinGroupOrder as any);
        expect(app.post).toHaveBeenCalledWith('/orders/:id/group/leave', { preHandler: [requireUser] }, leaveGroupOrder as any);
        expect(app.post).toHaveBeenCalledWith('/orders/:id/group/close', { preHandler: [requireUser] }, closeGroupOrder as any);
        expect(app.patch).toHaveBeenCalledWith('/orders/:id/split', { preHandler: [requireUser] }, splitOrderAmount as any);
        expect(app.post).toHaveBeenCalledWith('/orders/:id/refund', { preHandler: [requireUser] }, requestRefund as any);
        expect(app.get).toHaveBeenCalledWith('/refunds/me', { preHandler: [requireUser] }, getMyRefunds as any);
        expect(app.get).toHaveBeenCalledWith('/refunds/admin', { preHandler: [requireAdmin] }, listRefundsAdmin as any);
        expect(app.patch).toHaveBeenCalledWith('/refunds/:id/status', { preHandler: [requireAdmin] }, updateRefundStatusAdmin as any);
    });
});
