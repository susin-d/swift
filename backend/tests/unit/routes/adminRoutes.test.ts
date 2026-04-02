import { adminRoutes } from '../../../src/modules/admin/admin.routes';
import {
    getAdminOrders,
    getAdminUsers,
    getChartData,
    getDashboardSummary,
    getFinanceSummary,
} from '../../../src/controllers/adminController';
import { requireAdmin } from '../../../src/middleware/rbac';

describe('adminRoutes', () => {
    it('registers dashboard and finance summary contract routes', async () => {
        const app: any = {
            authenticate: jest.fn(),
            addHook: jest.fn(),
            get: jest.fn(),
            patch: jest.fn(),
            post: jest.fn(),
            delete: jest.fn(),
        };

        await adminRoutes(app);

        expect(app.addHook).toHaveBeenCalledWith('preValidation', app.authenticate);
        expect(app.get).toHaveBeenCalledWith('/dashboard/summary', { preHandler: [requireAdmin] }, getDashboardSummary);
        expect(app.get).toHaveBeenCalledWith('/charts', { preHandler: [requireAdmin] }, getChartData);
        expect(app.get).toHaveBeenCalledWith('/finance/summary', { preHandler: [requireAdmin] }, getFinanceSummary);
    });

    it('registers contract list routes used by the admin dashboard app', async () => {
        const app: any = {
            authenticate: jest.fn(),
            addHook: jest.fn(),
            get: jest.fn(),
            patch: jest.fn(),
            post: jest.fn(),
            delete: jest.fn(),
        };

        await adminRoutes(app);

        expect(app.get).toHaveBeenCalledWith('/orders', { preHandler: [requireAdmin] }, getAdminOrders);
        expect(app.get).toHaveBeenCalledWith('/users', { preHandler: [requireAdmin] }, getAdminUsers);
    });
});

describe('adminRoutes - bulk vendor operations', () => {
    it('registers POST /vendors/approve-many route with requireAdmin middleware', async () => {
        const app: any = {
            authenticate: jest.fn(),
            addHook: jest.fn(),
            get: jest.fn(),
            patch: jest.fn(),
            post: jest.fn(),
            delete: jest.fn(),
        };

        await adminRoutes(app);

        const postCalls = (app.post as jest.Mock).mock.calls;
        const approveManyCall = postCalls.find((call: any) => call[0] === '/vendors/approve-many');
        expect(approveManyCall).toBeDefined();
        expect(approveManyCall[1]).toEqual({ preHandler: [requireAdmin] });
    });

    it('registers POST /vendors/reject-many route with requireAdmin middleware', async () => {
        const app: any = {
            authenticate: jest.fn(),
            addHook: jest.fn(),
            get: jest.fn(),
            patch: jest.fn(),
            post: jest.fn(),
            delete: jest.fn(),
        };

        await adminRoutes(app);

        const postCalls = (app.post as jest.Mock).mock.calls;
        const rejectManyCall = postCalls.find((call: any) => call[0] === '/vendors/reject-many');
        expect(rejectManyCall).toBeDefined();
        expect(rejectManyCall[1]).toEqual({ preHandler: [requireAdmin] });
    });

    it('registers POST /users/block-many route with requireAdmin middleware', async () => {
        const app: any = {
            authenticate: jest.fn(),
            addHook: jest.fn(),
            get: jest.fn(),
            patch: jest.fn(),
            post: jest.fn(),
            delete: jest.fn(),
        };

        await adminRoutes(app);

        const postCalls = (app.post as jest.Mock).mock.calls;
        const blockManyCall = postCalls.find((call: any) => call[0] === '/users/block-many');
        expect(blockManyCall).toBeDefined();
        expect(blockManyCall[1]).toEqual({ preHandler: [requireAdmin] });
    });

    it('registers POST /users/role-many route with requireAdmin middleware', async () => {
        const app: any = {
            authenticate: jest.fn(),
            addHook: jest.fn(),
            get: jest.fn(),
            patch: jest.fn(),
            post: jest.fn(),
            delete: jest.fn(),
        };

        await adminRoutes(app);

        const postCalls = (app.post as jest.Mock).mock.calls;
        const roleManyCall = postCalls.find((call: any) => call[0] === '/users/role-many');
        expect(roleManyCall).toBeDefined();
        expect(roleManyCall[1]).toEqual({ preHandler: [requireAdmin] });
    });
});
