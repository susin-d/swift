import { FastifyInstance } from 'fastify';
import { getWalletBalance, getWalletTransactions, topupWallet } from '../controllers/walletController';
import { requireUser, requireUserOrAdmin } from '../middleware/rbac';

export const walletRoutes = async (app: FastifyInstance) => {
    app.addHook('preValidation', app.authenticate);
    app.get('/balance', { preHandler: [requireUser] }, getWalletBalance as any);
    app.patch('/topup', { preHandler: [requireUserOrAdmin] }, topupWallet as any);
    app.get('/transactions', { preHandler: [requireUser] }, getWalletTransactions as any);
};
