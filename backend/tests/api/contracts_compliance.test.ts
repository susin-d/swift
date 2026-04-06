import supertest from 'supertest';
import { FastifyInstance } from 'fastify';
import { buildApp } from '../../src/app';
import { CONTRACT_ENDPOINTS, CONTRACT_REGISTRY_VERSION } from '../../src/contracts/registry';
import { supabase } from '../../src/services/supabase';

/**
 * S9-04 — Contract Compliance Replay Tests
 *
 * These tests verify that:
 * 1. Every contract-registered endpoint exists (no 404) for authenticated requests
 * 2. Unauthenticated access to protected endpoints returns 401/403, not 404 or 5xx
 * 3. The registry shape and required fields are stable across builds
 */

describe('Contract Compliance — Registry Shape', () => {
    let app: FastifyInstance;

    beforeAll(async () => {
        app = await buildApp();
        await app.ready();
    });

    afterAll(async () => {
        await app.close();
    });

    it('registry version matches expected semver pattern', async () => {
        const response = await supertest(app.server as any)
            .get('/api/v1/contracts/registry');

        expect(response.status).toBe(200);
        expect(response.body.version).toBe(CONTRACT_REGISTRY_VERSION);
        expect(response.body.version).toMatch(/^\d{4}\.\d{2}\.s\d+\.\d+$/);
    });

    it('every contract endpoint has required structural fields', () => {
        for (const endpoint of CONTRACT_ENDPOINTS) {
            expect(endpoint.id).toBeTruthy();
            expect(endpoint.method).toMatch(/^(GET|POST|PATCH|DELETE)$/);
            expect(endpoint.path).toMatch(/^\/api\/v(1|2)\//);
            expect(['public', 'authenticated', 'user', 'admin', 'vendor']).toContain(endpoint.auth);
            expect(endpoint.response).toBeDefined();
            expect(Array.isArray(endpoint.response.fields)).toBe(true);
            expect(endpoint.response.fields.length).toBeGreaterThan(0);

            for (const field of endpoint.response.fields) {
                expect(field.name).toBeTruthy();
                expect(field.type).toBeTruthy();
                expect(typeof field.required).toBe('boolean');
                expect(field.description).toBeTruthy();
            }
        }
    });

    it('all contract methods are valid HTTP verbs', () => {
        const validMethods = ['GET', 'POST', 'PATCH', 'DELETE'];
        for (const endpoint of CONTRACT_ENDPOINTS) {
            expect(validMethods).toContain(endpoint.method);
        }
    });

    it('no duplicate endpoint IDs', () => {
        const ids = CONTRACT_ENDPOINTS.map(e => e.id);
        const uniqueIds = new Set(ids);
        expect(uniqueIds.size).toBe(ids.length);
    });

    it('all paths start with /api/v1/ or /api/v2/', () => {
        for (const endpoint of CONTRACT_ENDPOINTS) {
            expect(
                endpoint.path.startsWith('/api/v1/') || endpoint.path.startsWith('/api/v2/')
            ).toBe(true);
        }
    });

    it('registers secure v2 contract endpoints for sensitive finance/reward mutations', () => {
        const byId = new Map(CONTRACT_ENDPOINTS.map((endpoint) => [endpoint.id, endpoint]));

        expect(byId.get('wallet.topup.patch.v2')?.path).toBe('/api/v2/wallet/topup');
        expect(byId.get('loyalty.points.post.v2')?.path).toBe('/api/v2/loyalty/points');
        expect(byId.get('subscriptions.create.v2')?.path).toBe('/api/v2/subscriptions/create');
        expect(byId.get('subscriptions.renew.v2')?.path).toBe('/api/v2/subscriptions/:id/renew');

        expect(byId.get('loyalty.points.post.v2')?.auth).toBe('admin');
        expect(byId.get('subscriptions.create.v2')?.auth).toBe('admin');
        expect(byId.get('subscriptions.renew.v2')?.auth).toBe('admin');
    });

    it('total endpoint count is within registered bounds', async () => {
        const response = await supertest(app.server as any)
            .get('/api/v1/contracts/registry');

        expect(response.status).toBe(200);
        expect(response.body.totalEndpoints).toBe(CONTRACT_ENDPOINTS.length);
        expect(CONTRACT_ENDPOINTS.length).toBeGreaterThanOrEqual(10);
    });
});

describe('Contract Compliance — Auth Protection Replay', () => {
    let app: FastifyInstance;

    beforeAll(async () => {
        app = await buildApp();
        await app.ready();
    });

    afterAll(async () => {
        await app.close();
    });

    const protectedEndpoints = CONTRACT_ENDPOINTS.filter(e => e.auth !== 'public');

    it.each(protectedEndpoints.map(e => [e.id, e.method, e.path]))(
        '%s (%s %s) returns 401 (not 404/5xx) without token',
        async (_id: string, method: string, path: string) => {
            const m = method.toLowerCase() as 'get' | 'post' | 'patch' | 'delete';
            const response = await (supertest(app.server as any) as any)[m](path);

            expect(response.status).not.toBe(404);
            expect(response.status).not.toBe(500);
            expect(response.status).not.toBe(502);
            expect(response.status).not.toBe(503);
            // Must be 401 or (for role-gated) 403
            expect([401, 403]).toContain(response.status);
        }
    );
});

describe('Contract Compliance — Key Business Endpoints', () => {
    let app: FastifyInstance;

    beforeAll(async () => {
        app = await buildApp();
        await app.ready();
    });

    afterAll(async () => {
        await app.close();
    });

    it('auth.session.create contract is registered with correct shape', () => {
        const loginContract = CONTRACT_ENDPOINTS.find(e => e.id === 'auth.session.create');
        expect(loginContract).toBeDefined();
        expect(loginContract!.method).toBe('POST');
        expect(loginContract!.auth).toBe('public');
        expect(loginContract!.request).toBeDefined();

        const requestFields = loginContract!.request!.fields.map(f => f.name);
        expect(requestFields).toContain('email');
        expect(requestFields).toContain('password');

        const responseFields = loginContract!.response.fields.map(f => f.name);
        expect(responseFields).toContain('session.access_token');
        expect(responseFields).toContain('user.role');
    });

    it('orders.create contract includes eta in response fields', () => {
        const orderContract = CONTRACT_ENDPOINTS.find(e => e.id === 'orders.create');
        expect(orderContract).toBeDefined();
        expect(orderContract!.method).toBe('POST');
        expect(orderContract!.auth).not.toBe('public');

        const responseFields = orderContract!.response.fields.map(f => f.name);
        // eta field must be documented for consumer Contract correctness
        const hasEtaDoc = responseFields.some(f => f.startsWith('eta'));
        expect(hasEtaDoc).toBe(true);
    });

    it('auth.me.get contract documents user.role as required', () => {
        const meContract = CONTRACT_ENDPOINTS.find(e => e.id === 'auth.me.get');
        expect(meContract).toBeDefined();

        const roleField = meContract!.response.fields.find(f => f.name === 'user.role');
        expect(roleField).toBeDefined();
        expect(roleField!.required).toBe(true);
    });

    it('public login endpoint is reachable without relying on external auth network', async () => {
        const signInStub = jest.spyOn(supabase.auth, 'signInWithPassword').mockResolvedValue({
            data: { session: null, user: null } as any,
            error: { message: 'Invalid login credentials' } as any,
        });
        const response = await supertest(app.server as any)
            .post('/api/v1/auth/session')
            .send({ email: 'wrong@test.com', password: 'badpassword' });
        signInStub.mockRestore();

        // For bad credentials, endpoint should respond with auth error (never 404/5xx).
        expect(response.status).not.toBe(404);
        expect(response.status).not.toBe(500);
        expect([400, 401]).toContain(response.status);
    });
});
