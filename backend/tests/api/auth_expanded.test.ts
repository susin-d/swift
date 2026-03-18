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

    beforeEach(() => {
        mockSupabase.from.resetHistory();
        mockSupabase.from.resetBehavior();
        mockSupabase.auth.signUp.resetHistory();
        mockSupabase.auth.signUp.resetBehavior();
    });

    it('POST /register - should register a new student', async () => {
        const newUser = { id: 'new_123', email: 'student@campus.edu' };

        mockSupabase.auth.signUp.resolves({ data: { user: newUser as any, session: null }, error: null } as any);
        mockSupabase.from.withArgs('users').returns({
            insert: Sinon.stub().resolves({ error: null })
        } as any);
        mockSupabase.from.withArgs('customer_profiles').returns({
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

    it('POST /register - enforces user role regardless of payload role override', async () => {
        const newUser = { id: 'forced_user_1', email: 'override@campus.edu' };

        const usersInsertStub = Sinon.stub().resolves({ error: null });
        const profilesInsertStub = Sinon.stub().resolves({ error: null });

        mockSupabase.auth.signUp.resolves({ data: { user: newUser as any, session: null }, error: null } as any);
        mockSupabase.from.withArgs('users').returns({ insert: usersInsertStub } as any);
        mockSupabase.from.withArgs('customer_profiles').returns({ insert: profilesInsertStub } as any);

        const response = await supertest(app.server as any)
            .post('/api/v1/auth/register')
            .send({
                email: 'override@campus.edu',
                password: 'password123',
                name: 'Role Override',
                role: 'admin',
            });

        expect(response.status).toBe(201);
        Sinon.assert.calledOnce(mockSupabase.auth.signUp);
        expect(mockSupabase.auth.signUp.firstCall.args[0]).toMatchObject({
            options: {
                data: {
                    role: 'user',
                },
            },
        });
        Sinon.assert.calledWithExactly(usersInsertStub, {
            id: 'forced_user_1',
            name: 'Role Override',
            email: 'override@campus.edu',
            role: 'user',
        });
        Sinon.assert.calledWithExactly(profilesInsertStub, { id: 'forced_user_1' });
    });

    it('GET /me - should return authenticated user profile', async () => {
        mockSupabase.from.withArgs('users').returns({
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            single: Sinon.stub().resolves({ data: { id: 'user_123', role: 'user' }, error: null })
        } as any);
        mockSupabase.from.withArgs('customer_profiles').returns({
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            single: Sinon.stub().resolves({ data: { phone: '9999999999' }, error: null }),
        } as any);

        const response = await supertest(app.server as any)
            .get('/api/v1/auth/me')
            .set('Authorization', 'Bearer valid_user_token');

        expect(response.status).toBe(200);
        expect(response.body.user.id).toBe('user_123');
    });

    it('GET /me - returns token-derived fallback profile when db record is missing', async () => {
        mockSupabase.from.withArgs('users').returns({
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            single: Sinon.stub().resolves({ data: null, error: { message: 'Row not found' } }),
        } as any);

        const response = await supertest(app.server as any)
            .get('/api/v1/auth/me')
            .set('Authorization', 'Bearer valid_user_token');

        expect(response.status).toBe(200);
        expect(response.body).toEqual({
            user: {
                id: 'user_123',
                email: 'test@campus.edu',
                role: 'user',
                name: 'test',
                profile: {},
            },
        });
    });
});
