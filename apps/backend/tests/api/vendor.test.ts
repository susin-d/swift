import supertest from 'supertest';
import { buildApp } from '../../src/app';
import { FastifyInstance } from 'fastify';
import { mockSupabase } from '../mocks/supabaseMock';
import { mockAuthenticate } from '../mocks/authMock';
import Sinon from 'sinon';

describe('API - Vendor Operations', () => {
    let app: FastifyInstance;

    beforeAll(async () => {
        app = await buildApp(mockAuthenticate);
        await app.ready();
    });

    afterAll(async () => {
        await app.close();
        Sinon.restore();
    });

    it('GET /profile - returns 401 on missing token', async () => {
        const response = await supertest(app.server).get('/api/v1/vendor-ops/profile');
        expect(response.status).toBe(401);
    });

    it('GET /profile - returns vendor profile with valid token', async () => {
        // Mock chain
        const mockData = { name: 'Test Stall', owner_id: 'vendor_456' };
        mockSupabase.from.withArgs('vendors').returns({
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            single: Sinon.stub().resolves({ data: mockData, error: null })
        } as any);

        const response = await supertest(app.server as any)
            .get('/api/v1/vendor-ops/profile')
            .set('Authorization', 'Bearer valid_vendor_token');

        expect(response.status).toBe(200);
        expect(response.body.vendor).toEqual(mockData);
    });

    it('PATCH /profile - updates profile and returns data', async () => {
        const mockUpdate = { is_open: true };
        mockSupabase.from.withArgs('vendors').returns({
            update: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            select: Sinon.stub().returnsThis(),
            single: Sinon.stub().resolves({ data: mockUpdate, error: null })
        } as any);

        const response = await supertest(app.server as any)
            .patch('/api/v1/vendor-ops/profile')
            .set('Authorization', 'Bearer valid_vendor_token')
            .send(mockUpdate);

        expect(response.status).toBe(200);
        expect(response.body.vendor.is_open).toBe(true);
    });

    it('GET /store-controls - returns controls for authenticated vendor', async () => {
        mockSupabase.from.withArgs('vendors').returns({
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            single: Sinon.stub().resolves({ data: { id: 'ven-1', is_open: true }, error: null })
        } as any);

        mockSupabase.from.withArgs('vendor_settings').returns({
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            maybeSingle: Sinon.stub().resolves({
                data: {
                    preparation_time_avg: 18,
                    auto_accept_orders: true,
                    busy_mode_enabled: false,
                    busy_mode_message: null,
                    holiday_until: null,
                },
                error: null,
            })
        } as any);

        const response = await supertest(app.server as any)
            .get('/api/v1/vendor-ops/store-controls')
            .set('Authorization', 'Bearer valid_vendor_token');

        expect(response.status).toBe(200);
        expect(response.body.controls.vendor_id).toBe('ven-1');
        expect(response.body.controls.auto_accept_orders).toBe(true);
    });

    it('PATCH /store-controls - upserts controls and returns updated payload', async () => {
        const vendorChain = {
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            single: Sinon.stub().resolves({ data: { id: 'ven-1', is_open: true }, error: null }),
            update: Sinon.stub().returnsThis(),
        } as any;

        mockSupabase.from.withArgs('vendors').returns(vendorChain);

        const settingsSelectChain = {
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            maybeSingle: Sinon.stub().resolves({
                data: {
                    preparation_time_avg: 20,
                    auto_accept_orders: true,
                    busy_mode_enabled: true,
                    busy_mode_message: 'Busy',
                    holiday_until: null,
                },
                error: null,
            }),
            upsert: Sinon.stub().resolves({ error: null }),
        } as any;

        mockSupabase.from.withArgs('vendor_settings').returns(settingsSelectChain);

        const response = await supertest(app.server as any)
            .patch('/api/v1/vendor-ops/store-controls')
            .set('Authorization', 'Bearer valid_vendor_token')
            .send({
                is_open: true,
                auto_accept_orders: true,
                preparation_time_avg: 20,
                busy_mode_enabled: true,
                busy_mode_message: 'Busy',
            });

        expect(response.status).toBe(200);
        expect(response.body.controls.preparation_time_avg).toBe(20);
        expect(response.body.controls.busy_mode_enabled).toBe(true);
    });

    it('GET /finance/payouts - returns grouped payout data', async () => {
        mockSupabase.from.withArgs('vendors').returns({
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            single: Sinon.stub().resolves({ data: { id: 'ven-1', is_open: true }, error: null })
        } as any);

        mockSupabase.from.withArgs('orders').returns({
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            in: Sinon.stub().returnsThis(),
            order: Sinon.stub().resolves({
                data: [
                    { status: 'completed', total_amount: 150, created_at: '2026-03-10T10:00:00Z' },
                    { status: 'completed', total_amount: 250, created_at: '2026-03-11T10:00:00Z' },
                ],
                error: null,
            }),
        } as any);

        const response = await supertest(app.server as any)
            .get('/api/v1/vendor-ops/finance/payouts')
            .set('Authorization', 'Bearer valid_vendor_token');

        expect(response.status).toBe(200);
        expect(Array.isArray(response.body.payouts)).toBe(true);
        expect(response.body.payouts.length).toBeGreaterThan(0);
    });

    it('GET /finance/transactions - returns transaction rows', async () => {
        mockSupabase.from.withArgs('vendors').returns({
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            single: Sinon.stub().resolves({ data: { id: 'ven-1', is_open: true }, error: null })
        } as any);

        const ordersChain = {
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            order: Sinon.stub().returnsThis(),
            limit: Sinon.stub().resolves({
                data: [{ id: 'ord-1', total_amount: 200, status: 'completed', created_at: '2026-03-12T11:00:00Z' }],
                error: null,
            }),
        } as any;

        const paymentsChain = {
            select: Sinon.stub().returnsThis(),
            in: Sinon.stub().returnsThis(),
            order: Sinon.stub().resolves({
                data: [{ id: 'pay-1', order_id: 'ord-1', amount: 200, status: 'successful', provider_ref: 'rzp_1' }],
                error: null,
            }),
        } as any;

        mockSupabase.from.withArgs('orders').returns(ordersChain);
        mockSupabase.from.withArgs('payments').returns(paymentsChain);

        const response = await supertest(app.server as any)
            .get('/api/v1/vendor-ops/finance/transactions')
            .set('Authorization', 'Bearer valid_vendor_token');

        expect(response.status).toBe(200);
        expect(response.body.transactions[0].id).toBe('pay-1');
    });

    it('GET /analytics/performance - returns performance metrics', async () => {
        mockSupabase.from.withArgs('vendors').returns({
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            single: Sinon.stub().resolves({ data: { id: 'ven-1', is_open: true }, error: null })
        } as any);

        mockSupabase.from.withArgs('orders').returns({
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().resolves({
                data: [{ status: 'completed' }, { status: 'cancelled' }, { status: 'completed' }],
                error: null,
            }),
        } as any);

        const response = await supertest(app.server as any)
            .get('/api/v1/vendor-ops/analytics/performance')
            .set('Authorization', 'Bearer valid_vendor_token');

        expect(response.status).toBe(200);
        expect(response.body.metrics.total_orders).toBe(3);
        expect(response.body.metrics.completion_rate).toBeGreaterThan(0);
    });

    it('POST /staff/management - creates vendor staff member', async () => {
        mockSupabase.from.withArgs('vendors').returns({
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            single: Sinon.stub().resolves({ data: { id: 'ven-1', is_open: true }, error: null })
        } as any);

        mockSupabase.from.withArgs('vendor_staff_members').returns({
            insert: Sinon.stub().returnsThis(),
            select: Sinon.stub().returnsThis(),
            single: Sinon.stub().resolves({
                data: { id: 'staff-1', name: 'Kitchen Lead', role_key: 'manager', status: 'active' },
                error: null,
            }),
        } as any);

        const response = await supertest(app.server as any)
            .post('/api/v1/vendor-ops/staff/management')
            .set('Authorization', 'Bearer valid_vendor_token')
            .send({ name: 'Kitchen Lead', role_key: 'manager' });

        expect(response.status).toBe(201);
        expect(response.body.staff.id).toBe('staff-1');
    });

    it('PATCH /staff/management/:staffId - updates staff member', async () => {
        mockSupabase.from.withArgs('vendors').returns({
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            single: Sinon.stub().resolves({ data: { id: 'ven-1', is_open: true }, error: null })
        } as any);

        mockSupabase.from.withArgs('vendor_staff_members').returns({
            update: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            select: Sinon.stub().returnsThis(),
            maybeSingle: Sinon.stub().resolves({
                data: { id: 'staff-1', name: 'Kitchen Lead', role_key: 'cashier', status: 'active' },
                error: null,
            }),
        } as any);

        const response = await supertest(app.server as any)
            .patch('/api/v1/vendor-ops/staff/management/staff-1')
            .set('Authorization', 'Bearer valid_vendor_token')
            .send({ role_key: 'cashier' });

        expect(response.status).toBe(200);
        expect(response.body.staff.role_key).toBe('cashier');
    });

    it('POST /staff/invitations - creates invitation tied to identity', async () => {
        mockSupabase.from.withArgs('vendors').returns({
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            single: Sinon.stub().resolves({ data: { id: 'ven-1', is_open: true }, error: null })
        } as any);

        mockSupabase.from.withArgs('users').returns({
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            maybeSingle: Sinon.stub().resolves({ data: { id: 'user-1', email: 'staff@campus.edu' }, error: null }),
        } as any);

        mockSupabase.from.withArgs('vendor_staff_invitations').returns({
            insert: Sinon.stub().returnsThis(),
            select: Sinon.stub().returnsThis(),
            single: Sinon.stub().resolves({
                data: {
                    id: 'inv-1',
                    email: 'staff@campus.edu',
                    role_key: 'cashier',
                    status: 'pending',
                    invited_user_id: 'user-1',
                    invite_token: 'token-1',
                },
                error: null,
            }),
        } as any);

        const response = await supertest(app.server as any)
            .post('/api/v1/vendor-ops/staff/invitations')
            .set('Authorization', 'Bearer valid_vendor_token')
            .send({ email: 'staff@campus.edu', role_key: 'cashier' });

        expect(response.status).toBe(201);
        expect(response.body.invitation.id).toBe('inv-1');
        expect(response.body.invitation.invited_user_id).toBe('user-1');
    });

    it('PATCH /preferences/language - updates language settings', async () => {
        mockSupabase.from.withArgs('vendors').returns({
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            single: Sinon.stub().resolves({ data: { id: 'ven-1', is_open: true }, error: null })
        } as any);

        mockSupabase.from.withArgs('vendor_settings').returns({
            upsert: Sinon.stub().resolves({ error: null }),
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            maybeSingle: Sinon.stub().resolves({
                data: { preferred_language: 'Hindi' },
                error: null,
            }),
        } as any);

        const response = await supertest(app.server as any)
            .patch('/api/v1/vendor-ops/preferences/language')
            .set('Authorization', 'Bearer valid_vendor_token')
            .send({ current: 'Hindi' });

        expect(response.status).toBe(200);
        expect(response.body.language.current).toBe('Hindi');
    });

    it('PATCH /preferences/theme - updates theme settings', async () => {
        mockSupabase.from.withArgs('vendors').returns({
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            single: Sinon.stub().resolves({ data: { id: 'ven-1', is_open: true }, error: null })
        } as any);

        mockSupabase.from.withArgs('vendor_settings').returns({
            upsert: Sinon.stub().resolves({ error: null }),
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            maybeSingle: Sinon.stub().resolves({
                data: { theme_dark_mode: true, theme_high_contrast: false },
                error: null,
            }),
        } as any);

        const response = await supertest(app.server as any)
            .patch('/api/v1/vendor-ops/preferences/theme')
            .set('Authorization', 'Bearer valid_vendor_token')
            .send({ dark_mode: true });

        expect(response.status).toBe(200);
        expect(response.body.theme.dark_mode).toBe(true);
    });

    it('PATCH /preferences/app - updates app settings', async () => {
        mockSupabase.from.withArgs('vendors').returns({
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            single: Sinon.stub().resolves({ data: { id: 'ven-1', is_open: true }, error: null })
        } as any);

        mockSupabase.from.withArgs('vendor_settings').returns({
            upsert: Sinon.stub().resolves({ error: null }),
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            maybeSingle: Sinon.stub().resolves({
                data: {
                    app_compact_cards: true,
                    app_silent_alerts: false,
                    app_notification_enabled: true,
                    app_auto_print_receipts: true,
                    auto_accept_orders: false,
                    busy_mode_enabled: false,
                    preparation_time_avg: 15,
                },
                error: null,
            }),
        } as any);

        const response = await supertest(app.server as any)
            .patch('/api/v1/vendor-ops/preferences/app')
            .set('Authorization', 'Bearer valid_vendor_token')
            .send({ compact_cards: true, auto_print_receipts: true });

        expect(response.status).toBe(200);
        expect(response.body.app_settings.compact_cards).toBe(true);
        expect(response.body.app_settings.auto_print_receipts).toBe(true);
    });
});
