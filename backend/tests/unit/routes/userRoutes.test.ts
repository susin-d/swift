import { userRoutes } from '../../../src/routes/users';
import {
    cancelAccountDeletion,
    getAccountDeletionStatus,
    requestAccountDeletion,
} from '../../../src/controllers/userAccountController';
import { requireUser } from '../../../src/middleware/rbac';

describe('userRoutes', () => {
    it('registers account deletion workflow routes', async () => {
        const app: any = {
            authenticate: jest.fn(),
            addHook: jest.fn(),
            get: jest.fn(),
            delete: jest.fn(),
            patch: jest.fn(),
        };

        await userRoutes(app);

        expect(app.addHook).toHaveBeenCalledWith('preValidation', app.authenticate);
        expect(app.get).toHaveBeenCalledWith('/me/deletion', { preHandler: [requireUser] }, getAccountDeletionStatus);
        expect(app.delete).toHaveBeenCalledWith('/me', { preHandler: [requireUser] }, requestAccountDeletion);
        expect(app.patch).toHaveBeenCalledWith('/me/deletion/cancel', { preHandler: [requireUser] }, cancelAccountDeletion);
    });
});
