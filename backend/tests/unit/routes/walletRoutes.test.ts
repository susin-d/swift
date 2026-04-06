import { walletRoutes } from '../../../src/routes/wallet';
import {
    getWalletBalance,
    getWalletTransactions,
    topupWallet,
} from '../../../src/controllers/walletController';
import { requireUser, requireUserOrAdmin } from '../../../src/middleware/rbac';

describe('walletRoutes', () => {
    it('registers wallet routes with user guard', async () => {
        const app: any = {
            authenticate: jest.fn(),
            addHook: jest.fn(),
            get: jest.fn(),
            patch: jest.fn(),
        };

        await walletRoutes(app);

        expect(app.addHook).toHaveBeenCalledWith('preValidation', app.authenticate);
        expect(app.get).toHaveBeenCalledWith('/balance', { preHandler: [requireUser] }, getWalletBalance);
        expect(app.patch).toHaveBeenCalledWith('/topup', { preHandler: [requireUserOrAdmin] }, topupWallet);
        expect(app.get).toHaveBeenCalledWith('/transactions', { preHandler: [requireUser] }, getWalletTransactions);
    });
});
