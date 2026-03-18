import Sinon from 'sinon';

import { supabase } from '../../../src/services/supabase';
import {
    approveVendor,
    blockAdminUser,
    cancelAdminOrder,
    getAdminAuditLogs,
    getAdminOrders,
    getAdminSettings,
    getAdminUsers,
    getChartData,
    getDashboardSummary,
    getFinancePayouts,
    getFinanceSummary,
    getGlobalStats,
    getPendingVendors,
    rejectVendor,
    updateAdminSettings,
    updateAdminUserRole,
} from '../../../src/controllers/adminController';

describe('Admin Controller - Vendor Moderation', () => {
    let fromStub: Sinon.SinonStub;

    beforeEach(() => {
        fromStub = Sinon.stub(supabase, 'from');
    });

    afterEach(() => {
        Sinon.restore();
    });

    it('getPendingVendors returns paginated pending vendors payload', async () => {
        const data = [{ id: 'vendor-1', status: 'pending' }];
        const countEqStub = Sinon.stub().resolves({ count: 1, error: null });
        const countSelectStub = Sinon.stub().returns({ eq: countEqStub });

        const selectStub = Sinon.stub().returnsThis();
        const eqStub = Sinon.stub().returnsThis();
        const rangeStub = Sinon.stub().resolves({ data, error: null });
        const orderStub = Sinon.stub().returns({ range: rangeStub });

        fromStub.onFirstCall().returns({
            select: countSelectStub,
        } as any);

        fromStub.onSecondCall().returns({
            select: selectStub,
            eq: eqStub,
            order: orderStub,
        } as any);

        const request: any = { query: { page: '1', limit: '20' } };
        const reply: any = { send: Sinon.stub() };

        await getPendingVendors(request, reply);

        Sinon.assert.calledWithExactly(countSelectStub, '*', { count: 'exact', head: true });
        Sinon.assert.calledWithExactly(countEqStub, 'status', 'pending');
        Sinon.assert.calledWithExactly(selectStub, '*, owner:users(name, email)');
        Sinon.assert.calledWithExactly(eqStub, 'status', 'pending');
        Sinon.assert.calledWithExactly(orderStub, 'created_at', { ascending: false });
        Sinon.assert.calledWithExactly(rangeStub, 0, 19);
        Sinon.assert.calledOnce(reply.send);
        expect(reply.send.firstCall.args[0]).toEqual({
            vendors: data,
            page: 1,
            limit: 20,
            total: 1,
            meta: {
                page: 1,
                limit: 20,
                total: 1,
                totalPages: 1,
                hasNextPage: false,
                hasPreviousPage: false,
            },
        });
    });

    it('approveVendor updates status to approved', async () => {
        const updateStub = Sinon.stub().returnsThis();
        const eqStub = Sinon.stub().resolves({ error: null });

        fromStub.withArgs('vendors').returns({
            update: updateStub,
            eq: eqStub,
        } as any);

        const request: any = { params: { id: 'vendor-2' } };
        const reply: any = { send: Sinon.stub() };

        await approveVendor(request, reply);

        Sinon.assert.calledWithExactly(updateStub, { status: 'approved' });
        Sinon.assert.calledWithExactly(eqStub, 'id', 'vendor-2');
        Sinon.assert.calledOnce(reply.send);
        expect(reply.send.firstCall.args[0]).toEqual({ message: 'Vendor vendor-2 approved successfully' });
    });

    it('rejectVendor updates status to rejected', async () => {
        const updateStub = Sinon.stub().returnsThis();
        const eqStub = Sinon.stub().resolves({ error: null });

        fromStub.withArgs('vendors').returns({
            update: updateStub,
            eq: eqStub,
        } as any);

        const request: any = { params: { id: 'vendor-3' }, body: { reason: 'Policy violation reported' } };
        const reply: any = { send: Sinon.stub() };

        await rejectVendor(request, reply);

        Sinon.assert.calledWithExactly(updateStub, { status: 'rejected' });
        Sinon.assert.calledWithExactly(eqStub, 'id', 'vendor-3');
        Sinon.assert.calledOnce(reply.send);
        expect(reply.send.firstCall.args[0]).toEqual({ message: 'Vendor vendor-3 rejected successfully' });
    });

    it('getAdminOrders returns paginated payload with status filter', async () => {
        const countEqStub = Sinon.stub().resolves({ count: 2, error: null });
        const countSelectStub = Sinon.stub().returns({ eq: countEqStub });

        const orders = [{ id: 'o-1', status: 'pending' }, { id: 'o-2', status: 'pending' }];
        const rangeStub = Sinon.stub().returns({ eq: Sinon.stub().resolves({ data: orders, error: null }) });
        const orderStub = Sinon.stub().returns({ range: rangeStub });
        const ordersSelectStub = Sinon.stub().returns({ order: orderStub });

        fromStub.onFirstCall().returns({
            select: countSelectStub,
        } as any);

        fromStub.onSecondCall().returns({
            select: ordersSelectStub,
        } as any);

        const request: any = { query: { page: '2', limit: '5', status: 'pending' } };
        const reply: any = { send: Sinon.stub() };

        await getAdminOrders(request, reply);

        Sinon.assert.calledWithExactly(countSelectStub, '*', { count: 'exact', head: true });
        Sinon.assert.calledWithExactly(countEqStub, 'status', 'pending');
        Sinon.assert.calledWithExactly(ordersSelectStub, '*, users(name, email), vendors(name), order_items(quantity, unit_price)');
        Sinon.assert.calledWithExactly(orderStub, 'created_at', { ascending: false });
        Sinon.assert.calledWithExactly(rangeStub, 5, 9);

        expect(reply.send.firstCall.args[0]).toEqual({
            orders,
            page: 2,
            limit: 5,
            total: 2,
            meta: {
                page: 2,
                limit: 5,
                total: 2,
                totalPages: 1,
                hasNextPage: false,
                hasPreviousPage: true,
            },
        });
    });

    it('cancelAdminOrder sets order status to cancelled', async () => {
        const updateStub = Sinon.stub().returnsThis();
        const eqStub = Sinon.stub().resolves({ error: null });

        fromStub.withArgs('orders').returns({
            update: updateStub,
            eq: eqStub,
        } as any);

        const request: any = { params: { id: 'order-9' }, body: { reason: 'Customer requested cancellation' } };
        const reply: any = { send: Sinon.stub() };

        await cancelAdminOrder(request, reply);

        Sinon.assert.calledOnce(updateStub);
        Sinon.assert.calledWithMatch(updateStub, {
            status: 'cancelled',
            updated_at: Sinon.match.string,
        });
        Sinon.assert.calledWithExactly(eqStub, 'id', 'order-9');
        expect(reply.send.firstCall.args[0]).toEqual({ message: 'Order order-9 cancelled successfully' });
    });

    it('getAdminUsers returns paginated users with blocked flag', async () => {
        const users = [{ id: 'u-1', name: 'A', email: 'a@x.com', role: 'user', created_at: '2026-01-01' }];

        const countSelectStub = Sinon.stub().resolves({ count: 1, error: null });
        const usersRangeStub = Sinon.stub().resolves({ data: users, error: null });
        const usersOrderStub = Sinon.stub().returns({ range: usersRangeStub });
        const usersSelectStub = Sinon.stub().returns({ order: usersOrderStub });

        fromStub.onFirstCall().returns({ select: countSelectStub } as any);
        fromStub.onSecondCall().returns({ select: usersSelectStub } as any);

        const listUsersStub = Sinon.stub(supabase.auth.admin, 'listUsers').resolves({
            data: {
                users: [{ id: 'u-1', user_metadata: { is_blocked: true }, banned_until: null }],
            },
            error: null,
        } as any);

        const request: any = { query: { page: '1', limit: '20' } };
        const reply: any = { send: Sinon.stub() };

        await getAdminUsers(request, reply);

        Sinon.assert.calledWithExactly(countSelectStub, '*', { count: 'exact', head: true });
        Sinon.assert.calledWithExactly(usersSelectStub, 'id, name, email, role, created_at');
        Sinon.assert.calledWithExactly(usersOrderStub, 'created_at', { ascending: false });
        Sinon.assert.calledWithExactly(usersRangeStub, 0, 19);
        Sinon.assert.calledWithExactly(listUsersStub, { page: 1, perPage: 20 });

        expect(reply.send.firstCall.args[0]).toEqual({
            users: [{ ...users[0], blocked: true }],
            page: 1,
            limit: 20,
            total: 1,
            meta: {
                page: 1,
                limit: 20,
                total: 1,
                totalPages: 1,
                hasNextPage: false,
                hasPreviousPage: false,
            },
        });
    });

    it('blockAdminUser stores blocked metadata in auth user profile', async () => {
        const getUserStub = Sinon.stub(supabase.auth.admin, 'getUserById').resolves({
            data: { user: { user_metadata: { role: 'user' } } },
            error: null,
        } as any);
        const updateUserStub = Sinon.stub(supabase.auth.admin, 'updateUserById').resolves({
            data: {},
            error: null,
        } as any);

        const request: any = { params: { id: 'u-2' }, body: { blocked: true, reason: 'Terms of service violation' } };
        const reply: any = { send: Sinon.stub() };

        await blockAdminUser(request, reply);

        Sinon.assert.calledWithExactly(getUserStub, 'u-2');
        Sinon.assert.calledWithExactly(updateUserStub, 'u-2', {
            user_metadata: {
                role: 'user',
                is_blocked: true,
            },
        });
        expect(reply.send.firstCall.args[0]).toEqual({ message: 'User u-2 blocked successfully' });
    });

    it('updateAdminUserRole updates role in users and auth metadata', async () => {
        const updateStub = Sinon.stub().returnsThis();
        const eqStub = Sinon.stub().resolves({ error: null });

        fromStub.withArgs('users').returns({
            update: updateStub,
            eq: eqStub,
        } as any);

        const getUserStub = Sinon.stub(supabase.auth.admin, 'getUserById').resolves({
            data: { user: { user_metadata: { is_blocked: false } } },
            error: null,
        } as any);
        const updateUserStub = Sinon.stub(supabase.auth.admin, 'updateUserById').resolves({
            data: {},
            error: null,
        } as any);

        const request: any = { params: { id: 'u-3' }, body: { role: 'vendor' } };
        const reply: any = { send: Sinon.stub() };

        await updateAdminUserRole(request, reply);

        Sinon.assert.calledWithExactly(updateStub, { role: 'vendor' });
        Sinon.assert.calledWithExactly(eqStub, 'id', 'u-3');
        Sinon.assert.calledWithExactly(getUserStub, 'u-3');
        Sinon.assert.calledWithExactly(updateUserStub, 'u-3', {
            user_metadata: {
                is_blocked: false,
                role: 'vendor',
            },
        });
        expect(reply.send.firstCall.args[0]).toEqual({ message: 'User u-3 role updated to vendor successfully' });
    });

    it('getFinanceSummary returns today/week/month/total revenue', async () => {
        const now = new Date();
        const data = [
            { total_amount: 100, created_at: now.toISOString(), status: 'completed' },
            { total_amount: 200, created_at: new Date(now.getTime() - 2 * 24 * 60 * 60 * 1000).toISOString(), status: 'completed' },
            { total_amount: 300, created_at: new Date(now.getTime() - 40 * 24 * 60 * 60 * 1000).toISOString(), status: 'completed' },
        ];

        const eqStub = Sinon.stub().resolves({ data, error: null });
        const selectStub = Sinon.stub().returns({ eq: eqStub });

        fromStub.withArgs('orders').returns({
            select: selectStub,
        } as any);

        const reply: any = { send: Sinon.stub() };
        await getFinanceSummary({} as any, reply);

        Sinon.assert.calledWithExactly(selectStub, 'total_amount, created_at, status');
        Sinon.assert.calledWithExactly(eqStub, 'status', 'completed');

        const payload = reply.send.firstCall.args[0];
        expect(payload.summary.total_revenue).toBe(600);
        expect(payload.summary.today_revenue).toBe(100);
        expect(payload.summary.week_revenue).toBe(300);
        expect(payload.summary.month_revenue).toBeGreaterThanOrEqual(300);
    });

    it('getDashboardSummary returns aggregated counts and completed revenue', async () => {
        const userSelectStub = Sinon.stub().resolves({ count: 12, error: null });
        const vendorSelectStub = Sinon.stub().resolves({ count: 4, error: null });
        const orderCountSelectStub = Sinon.stub().resolves({ count: 9, error: null });

        const completedOrdersEqStub = Sinon.stub().resolves({
            data: [
                { total_amount: 120, status: 'completed' },
                { total_amount: '80', status: 'completed' },
            ],
            error: null,
        });
        const completedOrdersSelectStub = Sinon.stub().returns({ eq: completedOrdersEqStub });

        fromStub.onCall(0).returns({ select: userSelectStub } as any);
        fromStub.onCall(1).returns({ select: vendorSelectStub } as any);
        fromStub.onCall(2).returns({ select: orderCountSelectStub } as any);
        fromStub.onCall(3).returns({ select: completedOrdersSelectStub } as any);

        const reply: any = { send: Sinon.stub() };

        await getDashboardSummary({} as any, reply);

        Sinon.assert.calledWithExactly(userSelectStub, '*', { count: 'exact', head: true });
        Sinon.assert.calledWithExactly(vendorSelectStub, '*', { count: 'exact', head: true });
        Sinon.assert.calledWithExactly(orderCountSelectStub, '*', { count: 'exact', head: true });
        Sinon.assert.calledWithExactly(completedOrdersSelectStub, 'total_amount, status');
        Sinon.assert.calledWithExactly(completedOrdersEqStub, 'status', 'completed');

        expect(reply.send.firstCall.args[0]).toEqual({
            summary: {
                total_users: 12,
                total_vendors: 4,
                active_orders: 9,
                completed_orders: 2,
                revenue: 200,
            },
        });
    });

    it('getGlobalStats returns contract revenue field with gmv alias', async () => {
        const userSelectStub = Sinon.stub().resolves({ count: 20, error: null });
        const vendorSelectStub = Sinon.stub().resolves({ count: 6, error: null });
        const orderCountSelectStub = Sinon.stub().resolves({ count: 14, error: null });

        const completedOrdersEqStub = Sinon.stub().resolves({
            data: [
                { total_amount: 75 },
                { total_amount: '25' },
            ],
            error: null,
        });
        const completedOrdersSelectStub = Sinon.stub().returns({ eq: completedOrdersEqStub });

        fromStub.onCall(0).returns({ select: userSelectStub } as any);
        fromStub.onCall(1).returns({ select: vendorSelectStub } as any);
        fromStub.onCall(2).returns({ select: orderCountSelectStub } as any);
        fromStub.onCall(3).returns({ select: completedOrdersSelectStub } as any);

        const reply: any = { send: Sinon.stub() };

        await getGlobalStats({} as any, reply);

        const payload = reply.send.firstCall.args[0];
        expect(payload.stats).toEqual({
            users: 20,
            vendors: 6,
            orders: 14,
            revenue: 100,
            gmv: 100,
        });
    });

    it('getChartData returns seven-day chart and only counts completed revenue', async () => {
        const now = new Date();
        const orders = [
            {
                created_at: new Date(now.getTime() - 24 * 60 * 60 * 1000).toISOString(),
                total_amount: 150,
                status: 'completed',
            },
            {
                created_at: new Date(now.getTime() - 2 * 24 * 60 * 60 * 1000).toISOString(),
                total_amount: 90,
                status: 'preparing',
            },
            {
                created_at: new Date(now.getTime() - 3 * 24 * 60 * 60 * 1000).toISOString(),
                total_amount: 50,
                status: 'completed',
            },
        ];

        const orderByStub = Sinon.stub().resolves({ data: orders, error: null });
        const gteStub = Sinon.stub().returns({ order: orderByStub });
        const selectStub = Sinon.stub().returns({ gte: gteStub });

        fromStub.withArgs('orders').returns({ select: selectStub } as any);

        const reply: any = { send: Sinon.stub() };

        await getChartData({} as any, reply);

        Sinon.assert.calledWithExactly(selectStub, 'created_at, total_amount, status');
        Sinon.assert.calledWithExactly(orderByStub, 'created_at', { ascending: true });

        const payload = reply.send.firstCall.args[0];
        expect(payload.chartData).toHaveLength(7);
        expect(payload.chartData.map((d: any) => d.name).sort()).toEqual(['Fri', 'Mon', 'Sat', 'Sun', 'Thu', 'Tue', 'Wed'].sort());

        const totalOrders = payload.chartData.reduce((sum: number, d: any) => sum + d.orders, 0);
        const totalRevenue = payload.chartData.reduce((sum: number, d: any) => sum + d.revenue, 0);

        expect(totalOrders).toBe(3);
        expect(totalRevenue).toBe(200);
    });

    it('getFinancePayouts groups completed orders by vendor', async () => {
        const data = [
            { vendor_id: 'v-1', total_amount: 120, status: 'completed', vendors: { name: 'Alpha' } },
            { vendor_id: 'v-1', total_amount: 80, status: 'completed', vendors: { name: 'Alpha' } },
            { vendor_id: 'v-2', total_amount: 50, status: 'completed', vendors: { name: 'Beta' } },
        ];

        const eqStub = Sinon.stub().resolves({ data, error: null });
        const selectStub = Sinon.stub().returns({ eq: eqStub });

        fromStub.withArgs('orders').returns({
            select: selectStub,
        } as any);

        const reply: any = { send: Sinon.stub() };
        await getFinancePayouts({} as any, reply);

        Sinon.assert.calledWithExactly(selectStub, 'vendor_id, total_amount, status, vendors(name)');
        Sinon.assert.calledWithExactly(eqStub, 'status', 'completed');

        const payload = reply.send.firstCall.args[0];
        expect(payload.payouts).toHaveLength(2);
        expect(payload.payouts[0]).toMatchObject({ vendor_id: 'v-1', total_orders: 2, total_revenue: 200 });
    });

    it('getAdminAuditLogs returns paginated logs with action filter', async () => {
        const countEqStub = Sinon.stub().resolves({ count: 1, error: null });
        const countSelectStub = Sinon.stub().returns({ eq: countEqStub });

        const logs = [{ id: 'l-1', action_performed: 'approve_vendor' }];
        const rangeStub = Sinon.stub().returns({ eq: Sinon.stub().resolves({ data: logs, error: null }) });
        const orderStub = Sinon.stub().returns({ range: rangeStub });
        const dataSelectStub = Sinon.stub().returns({ order: orderStub });

        fromStub.onFirstCall().returns({ select: countSelectStub } as any);
        fromStub.onSecondCall().returns({ select: dataSelectStub } as any);

        const request: any = { query: { page: '1', limit: '20', action: 'approve_vendor' } };
        const reply: any = { send: Sinon.stub() };

        await getAdminAuditLogs(request, reply);

        Sinon.assert.calledWithExactly(countSelectStub, '*', { count: 'exact', head: true });
        Sinon.assert.calledWithExactly(countEqStub, 'action_performed', 'approve_vendor');
        expect(reply.send.firstCall.args[0]).toEqual({
            logs,
            page: 1,
            limit: 20,
            total: 1,
            meta: {
                page: 1,
                limit: 20,
                total: 1,
                totalPages: 1,
                hasNextPage: false,
                hasPreviousPage: false,
            },
        });
    });

    it('getAdminSettings returns settings payload', async () => {
        const reply: any = { send: Sinon.stub() };

        await getAdminSettings({} as any, reply);

        expect(reply.send.firstCall.args[0]).toHaveProperty('settings');
    });

    it('updateAdminSettings rejects non-super-admin user', async () => {
        const request: any = {
            user: { role: 'admin', email: 'admin@x.com' },
            body: { commission_rate: 10, delivery_fee: 20 },
        };
        const reply: any = { send: Sinon.stub() };

        await expect(updateAdminSettings(request, reply)).rejects.toMatchObject({ statusCode: 403 });
    });

    it('rejectVendor rejects with 400 when reason is missing', async () => {
        const request: any = { params: { id: 'vendor-x' }, body: {} };
        const reply: any = { send: Sinon.stub() };

        await expect(rejectVendor(request, reply)).rejects.toMatchObject({ statusCode: 400 });
    });

    it('cancelAdminOrder rejects with 400 when reason is missing', async () => {
        const request: any = { params: { id: 'order-x' }, body: {} };
        const reply: any = { send: Sinon.stub() };

        await expect(cancelAdminOrder(request, reply)).rejects.toMatchObject({ statusCode: 400 });
    });

    it('blockAdminUser rejects with 400 when blocking without reason', async () => {
        const request: any = { params: { id: 'u-x' }, body: { blocked: true } };
        const reply: any = { send: Sinon.stub() };

        await expect(blockAdminUser(request, reply)).rejects.toMatchObject({ statusCode: 400 });
    });
});
