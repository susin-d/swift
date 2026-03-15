import supertest from 'supertest';
import { FastifyInstance } from 'fastify';
import { buildApp } from '../../src/app';

describe('API - Contracts Registry', () => {
    let app: FastifyInstance;

    beforeAll(async () => {
        app = await buildApp();
        await app.ready();
    });

    afterAll(async () => {
        await app.close();
    });

    it('GET /registry - returns canonical contract manifest', async () => {
        const response = await supertest(app.server as any)
            .get('/api/v1/contracts/registry');

        expect(response.status).toBe(200);
        expect(response.body.version).toBeDefined();
        expect(Array.isArray(response.body.endpoints)).toBe(true);
        expect(response.body.totalEndpoints).toBeGreaterThan(0);

        const sessionContract = response.body.endpoints.find((endpoint: any) => endpoint.id === 'auth.session.create');
        expect(sessionContract).toBeDefined();
        expect(sessionContract.path).toBe('/api/v1/auth/session');
        expect(sessionContract.method).toBe('POST');
    });

    it('GET /changelog - returns contract changelog feed', async () => {
        const response = await supertest(app.server as any)
            .get('/api/v1/contracts/changelog');

        expect(response.status).toBe(200);
        expect(response.body.version).toBeDefined();
        expect(Array.isArray(response.body.changes)).toBe(true);
        expect(response.body.count).toBeGreaterThan(0);
    });

    it('GET /flags - returns staged contract feature flags', async () => {
        const response = await supertest(app.server as any)
            .get('/api/v1/contracts/flags');

        expect(response.status).toBe(200);
        expect(response.body.version).toBeDefined();
        expect(Array.isArray(response.body.flags)).toBe(true);
        expect(response.body.count).toBeGreaterThan(0);

        const taxonomyFlag = response.body.flags.find((flag: any) => flag.key === 'contracts.error_taxonomy.v2');
        expect(taxonomyFlag).toBeDefined();
        expect(taxonomyFlag.enabled).toBe(true);
    });
});
