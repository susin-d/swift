import supertest from 'supertest';
import { FastifyInstance } from 'fastify';
import { buildApp } from '../../src/app';

describe('API - Performance Budgets', () => {
    let app: FastifyInstance;

    beforeAll(async () => {
        app = await buildApp();
        await app.ready();
    });

    afterAll(async () => {
        await app.close();
    });

    it('contracts registry payload stays within size budget', async () => {
        const response = await supertest(app.server as any).get('/api/v1/contracts/registry');
        expect(response.status).toBe(200);

        const payloadBytes = Buffer.byteLength(JSON.stringify(response.body), 'utf8');
        // Prevent silent response bloat in a high-read endpoint consumed by all apps.
        expect(payloadBytes).toBeLessThanOrEqual(700 * 1024);
    });

    it('contracts changelog payload stays within size budget', async () => {
        const response = await supertest(app.server as any).get('/api/v1/contracts/changelog');
        expect(response.status).toBe(200);

        const payloadBytes = Buffer.byteLength(JSON.stringify(response.body), 'utf8');
        expect(payloadBytes).toBeLessThanOrEqual(256 * 1024);
    });
});

