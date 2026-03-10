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
});
