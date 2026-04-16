import { FastifyInstance } from 'fastify';
import { getWalletBalance, getWalletTransactions, topupWallet, createTopupPayment, verifyAndCompleteTopup } from '../controllers/walletController';
import { requireUser, requireUserOrAdmin } from '../middleware/rbac';

export const walletRoutes = async (app: FastifyInstance) => {
    app.addHook('preValidation', app.authenticate);
    
    app.get('/balance', { preHandler: [requireUser] }, getWalletBalance as any);
    app.patch('/topup', { preHandler: [requireUserOrAdmin] }, topupWallet as any);
    app.get('/transactions', { preHandler: [requireUser] }, getWalletTransactions as any);

    // Razorpay Wallet Topup
    app.post('/create-payment', { preHandler: [requireUser] }, createTopupPayment as any);
    app.post('/verify-topup', { preHandler: [requireUser] }, verifyAndCompleteTopup as any);
};
