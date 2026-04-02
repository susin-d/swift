import { FastifyInstance } from 'fastify';
import { requireUser } from '../middleware/rbac';
import { getWalletBalance, topupWallet, getWalletTransactions, debitWallet } from '../controllers/walletController';

export const walletRoutes = async (app: FastifyInstance) => {
    app.addHook('preValidation', app.authenticate);
    app.get('/', { preHandler: [requireUser] }, getWalletBalance);
    app.patch('/topup', { preHandler: [requireUser] }, topupWallet);
    app.get('/transactions', { preHandler: [requireUser] }, getWalletTransactions);
    app.patch('/debit', { preHandler: [requireUser] }, debitWallet);
};
