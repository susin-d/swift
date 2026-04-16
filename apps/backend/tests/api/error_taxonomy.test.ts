import supertest from 'supertest';
import { FastifyInstance } from 'fastify';
import Sinon from 'sinon';

import { buildApp } from '../../src/app';
import { mockAuthenticate } from '../mocks/authMock';
import { mockSupabase } from '../mocks/supabaseMock';

describe('API - Error Taxonomy Envelope', () => {
    let app: FastifyInstance;

    beforeAll(async () => {
        app = await buildApp(mockAuthenticate);
        app.get('/api/v1/test-conflict', async () => {
            const err = new Error('Duplicate resource') as any;
            err.statusCode = 409;
            throw err;
        });
        await app.ready();
    });

    afterAll(async () => {
        await app.close();
        Sinon.restore();
    });

    it('returns ValidationError for 400 payload validation failures', async () => {
        const response = await supertest(app.server as any)
            .patch('/api/v1/auth/me')
            .set('Authorization', 'Bearer valid_user_token')
            .send({});

        expect(response.status).toBe(400);
        expect(response.body).toMatchObject({
            error: 'ValidationError'
        });
        expect(typeof response.body.message).toBe('string');
    });

    it('returns Unauthorized for 401 auth failures', async () => {
        const response = await supertest(app.server as any)
            .get('/api/v1/auth/me');

        expect(response.status).toBe(401);
        expect(response.body).toEqual({
            error: 'Unauthorized',
            message: 'Missing or invalid token'
        });
    });

    it('returns Forbidden for 403 RBAC failures', async () => {
        const response = await supertest(app.server as any)
            .get('/api/v1/admin/stats')
            .set('Authorization', 'Bearer valid_user_token');

        expect(response.status).toBe(403);
        expect(response.body).toMatchObject({
            error: 'Forbidden',
            message: 'You do not have permission to access this resource'
        });
    });

    it('returns NotFound for 404 unknown routes', async () => {
        const response = await supertest(app.server as any)
            .get('/api/v1/unknown-resource');

        expect(response.status).toBe(404);
        expect(response.body).toEqual({
            error: 'NotFound',
            message: 'Resource not found'
        });
    });

    it('returns Conflict for 409 conflict errors', async () => {
        const response = await supertest(app.server as any)
            .get('/api/v1/test-conflict');

        expect(response.status).toBe(409);
        expect(response.body).toEqual({
            error: 'Conflict',
            message: 'Duplicate resource'
        });
    });

    it('returns InternalServerError for unhandled server faults', async () => {
        mockSupabase.from.withArgs('users').returns({
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            single: Sinon.stub().rejects(new Error('db offline'))
        } as any);

        const response = await supertest(app.server as any)
            .get('/api/v1/auth/me')
            .set('Authorization', 'Bearer valid_user_token');

        expect(response.status).toBe(500);
        expect(response.body).toMatchObject({
            error: 'InternalServerError',
            message: 'An internal server error occurred'
        });
    });
});
