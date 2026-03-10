import { mockSupabase } from '../mocks/supabaseMock';
import { mockAuthenticate } from '../mocks/authMock';
import supertest from 'supertest';
import { buildApp } from '../../src/app';
import { FastifyInstance } from 'fastify';
import Sinon from 'sinon';

describe('API - Auth Controller Expansion', () => {
    let app: FastifyInstance;

    beforeAll(async () => {
        app = await buildApp(mockAuthenticate);
        await app.ready();
    });

    afterAll(async () => {
        await app.close();
        Sinon.restore();
    });

    it('POST /register - should register a new student', async () => {
        const newUser = { id: 'new_123', email: 'student@campus.edu' };

        mockSupabase.auth.signUp.resolves({ data: { user: newUser as any, session: null }, error: null } as any);
        mockSupabase.from.withArgs('users').returns({
            insert: Sinon.stub().resolves({ error: null })
        } as any);

        const response = await supertest(app.server as any)
            .post('/api/v1/auth/register')
            .send({
                email: 'student@campus.edu',
                password: 'password123',
                name: 'John Doe',
                role: 'user'
            });

        expect(response.status).toBe(201);
        expect(response.body.user.id).toBe('new_123');
    });

    it('GET /me - should return authenticated user profile', async () => {
        mockSupabase.from.withArgs('users').returns({
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            single: Sinon.stub().resolves({ data: { id: 'user_123', role: 'user' }, error: null })
        } as any);

        const response = await supertest(app.server as any)
            .get('/api/v1/auth/me')
            .set('Authorization', 'Bearer valid_user_token');

        expect(response.status).toBe(200);
        expect(response.body.user.id).toBe('user_123');
    });
});
