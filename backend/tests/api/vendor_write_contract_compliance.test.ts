import supertest from 'supertest';
import { FastifyInstance } from 'fastify';
import Sinon from 'sinon';
import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';

import { buildApp } from '../../src/app';
import { CONTRACT_ENDPOINTS } from '../../src/contracts/registry';
import { mockAuthenticate } from '../mocks/authMock';
import { mockSupabase } from '../mocks/supabaseMock';

type AnyRecord = Record<string, any>;

const getByPath = (obj: AnyRecord, path: string): unknown => {
    return path
        .split('.')
        .reduce((acc: any, key) => (acc == null ? undefined : acc[key]), obj);
};

const assertContractFieldsExist = (payload: AnyRecord, endpointId: string, requiredRoots: string[]) => {
    const contract = CONTRACT_ENDPOINTS.find((entry) => entry.id === endpointId);
    expect(contract).toBeDefined();

    for (const field of contract!.response.fields) {
        const root = field.name.split('.')[0];
        if (!requiredRoots.includes(root)) continue;

        const value = getByPath(payload, field.name);
        if (field.required) {
            expect(value).toBeDefined();
        }
    }
};

describe('API - Vendor Write Contract Compliance', () => {
    let app: FastifyInstance;

    beforeAll(async () => {
        app = await buildApp(mockAuthenticate);
        await app.ready();
    });

    afterAll(async () => {
        await app.close();
        Sinon.restore();
    });

    it('POST /vendor-ops/staff/invitations complies with contract response fields', async () => {
        mockSupabase.from.withArgs('vendors').returns({
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            single: Sinon.stub().resolves({ data: { id: 'ven-1', is_open: true }, error: null }),
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
                    invite_token: 'token-1',
                },
                error: null,
            }),
        } as any);

        mockSupabase.from.withArgs('admin_logs').returns({
            insert: Sinon.stub().resolves({ error: null }),
        } as any);

        const response = await supertest(app.server as any)
            .post('/api/v1/vendor-ops/staff/invitations')
            .set('Authorization', 'Bearer valid_vendor_token')
            .send({ email: 'staff@campus.edu', role_key: 'cashier' });

        expect(response.status).toBe(201);
        assertContractFieldsExist(response.body, 'vendor.staff.invitations.create', ['invitation']);
    });

    it('POST /vendor-ops/staff/management complies with contract response fields', async () => {
        mockSupabase.from.withArgs('vendors').returns({
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            single: Sinon.stub().resolves({ data: { id: 'ven-1', is_open: true }, error: null }),
        } as any);

        mockSupabase.from.withArgs('vendor_staff_members').returns({
            insert: Sinon.stub().returnsThis(),
            select: Sinon.stub().returnsThis(),
            single: Sinon.stub().resolves({
                data: {
                    id: 'staff-1',
                    name: 'Kitchen Lead',
                    role_key: 'manager',
                    status: 'active',
                },
                error: null,
            }),
        } as any);

        mockSupabase.from.withArgs('admin_logs').returns({
            insert: Sinon.stub().resolves({ error: null }),
        } as any);

        const response = await supertest(app.server as any)
            .post('/api/v1/vendor-ops/staff/management')
            .set('Authorization', 'Bearer valid_vendor_token')
            .send({ name: 'Kitchen Lead', role_key: 'manager' });

        expect(response.status).toBe(201);
        assertContractFieldsExist(response.body, 'vendor.staff.management.create', ['staff']);
    });

    it('PATCH /vendor-ops/staff/roles complies with contract response fields', async () => {
        mockSupabase.from.withArgs('vendors').returns({
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            single: Sinon.stub().resolves({ data: { id: 'ven-1', is_open: true }, error: null }),
        } as any);

        const rolesChain = {
            upsert: Sinon.stub().resolves({ error: null }),
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            order: Sinon.stub().resolves({
                data: [{ role_key: 'manager', permissions: ['orders.manage'] }],
                error: null,
            }),
        } as any;

        mockSupabase.from.withArgs('vendor_staff_roles').returns(rolesChain);
        mockSupabase.from.withArgs('admin_logs').returns({
            insert: Sinon.stub().resolves({ error: null }),
        } as any);

        const response = await supertest(app.server as any)
            .patch('/api/v1/vendor-ops/staff/roles')
            .set('Authorization', 'Bearer valid_vendor_token')
            .send({ roles: [{ key: 'manager', permissions: ['orders.manage'] }] });

        expect(response.status).toBe(200);
        assertContractFieldsExist(response.body, 'vendor.staff.roles.patch', ['roles']);
    });

    it('PATCH /vendor-ops/preferences/language complies with contract response fields', async () => {
        mockSupabase.from.withArgs('vendors').returns({
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            single: Sinon.stub().resolves({ data: { id: 'ven-1', is_open: true }, error: null }),
        } as any);

        mockSupabase.from.withArgs('vendor_settings').returns({
            upsert: Sinon.stub().resolves({ error: null }),
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            maybeSingle: Sinon.stub().resolves({ data: { preferred_language: 'Hindi' }, error: null }),
        } as any);

        mockSupabase.from.withArgs('admin_logs').returns({
            insert: Sinon.stub().resolves({ error: null }),
        } as any);

        const response = await supertest(app.server as any)
            .patch('/api/v1/vendor-ops/preferences/language')
            .set('Authorization', 'Bearer valid_vendor_token')
            .send({ current: 'Hindi' });

        expect(response.status).toBe(200);
        assertContractFieldsExist(response.body, 'vendor.preferences.language.patch', ['language']);
    });

    it('PATCH /vendor-ops/preferences/theme complies with contract response fields', async () => {
        mockSupabase.from.withArgs('vendors').returns({
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            single: Sinon.stub().resolves({ data: { id: 'ven-1', is_open: true }, error: null }),
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

        mockSupabase.from.withArgs('admin_logs').returns({
            insert: Sinon.stub().resolves({ error: null }),
        } as any);

        const response = await supertest(app.server as any)
            .patch('/api/v1/vendor-ops/preferences/theme')
            .set('Authorization', 'Bearer valid_vendor_token')
            .send({ dark_mode: true });

        expect(response.status).toBe(200);
        assertContractFieldsExist(response.body, 'vendor.preferences.theme.patch', ['theme']);
    });

    it('PATCH /vendor-ops/preferences/app complies with contract response fields', async () => {
        mockSupabase.from.withArgs('vendors').returns({
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            single: Sinon.stub().resolves({ data: { id: 'ven-1', is_open: true }, error: null }),
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

        mockSupabase.from.withArgs('admin_logs').returns({
            insert: Sinon.stub().resolves({ error: null }),
        } as any);

        const response = await supertest(app.server as any)
            .patch('/api/v1/vendor-ops/preferences/app')
            .set('Authorization', 'Bearer valid_vendor_token')
            .send({ compact_cards: true, auto_print_receipts: true });

        expect(response.status).toBe(200);
        assertContractFieldsExist(response.body, 'vendor.preferences.app.patch', ['app_settings']);
    });

    it('POST /auth/staff/onboarding/accept complies with contract response fields', async () => {
        mockSupabase.from.withArgs('vendor_staff_invitations').returns({
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            maybeSingle: Sinon.stub().resolves({
                data: {
                    id: 'inv-1',
                    vendor_id: 'ven-1',
                    role_key: 'cashier',
                    invited_user_id: 'user_123',
                    email: 'test@campus.edu',
                    status: 'pending',
                    expires_at: new Date(Date.now() + 86400000).toISOString(),
                },
                error: null,
            }),
            update: Sinon.stub().returnsThis(),
        } as any);

        mockSupabase.from.withArgs('vendor_staff_members').returns({
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            maybeSingle: Sinon.stub().resolves({ data: null, error: null }),
            insert: Sinon.stub().resolves({ error: null }),
        } as any);

        mockSupabase.from.withArgs('admin_logs').returns({
            insert: Sinon.stub().resolves({ error: null }),
        } as any);

        const response = await supertest(app.server as any)
            .post('/api/v1/auth/staff/onboarding/accept')
            .set('Authorization', 'Bearer valid_user_token')
            .send({ token: 'token-1' });

        expect(response.status).toBe(200);
        assertContractFieldsExist(response.body, 'auth.staff.onboarding.accept', ['onboarding']);
    });
});
