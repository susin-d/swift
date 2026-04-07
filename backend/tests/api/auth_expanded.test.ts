import { afterAll, beforeAll, beforeEach, describe, expect, it } from '@jest/globals';
import { mockSupabase } from '../mocks/supabaseMock';
import { mockAuthenticate } from '../mocks/authMock';
import supertest from 'supertest';
import { buildApp } from '../../src/app';
import { FastifyInstance } from 'fastify';
import Sinon from 'sinon';

describe('API - Auth Controller Expansion', () => {
    let app: FastifyInstance;
    let fetchStub: Sinon.SinonStub;

    beforeAll(async () => {
        app = await buildApp(mockAuthenticate);
        await app.ready();
        fetchStub = Sinon.stub(globalThis as any, 'fetch');
    });

    afterAll(async () => {
        fetchStub.restore();
        await app.close();
        Sinon.restore();
    });

    beforeEach(() => {
        mockSupabase.from.resetHistory();
        mockSupabase.from.resetBehavior();
        mockSupabase.auth.signUp.resetHistory();
        mockSupabase.auth.signUp.resetBehavior();
        mockSupabase.auth.admin.updateUserById.resetHistory();
        mockSupabase.auth.admin.updateUserById.resetBehavior();
        fetchStub.resetHistory();
        fetchStub.resetBehavior();
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

    it('POST /staff/onboarding/accept - accepts onboarding token for authenticated user', async () => {
        mockSupabase.from.withArgs('vendor_staff_invitations').returns({
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            maybeSingle: Sinon.stub()
                .onFirstCall()
                .resolves({
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
                })
                .onSecondCall()
                .returnsThis(),
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
            .send({ token: 'invite-token' });

        expect(response.status).toBe(200);
        expect(response.body.onboarding.status).toBe('accepted');
        expect(response.body.onboarding.role_key).toBe('cashier');
    });

    it('POST /password/forgot - returns generic success when account is unknown', async () => {
        mockSupabase.from.withArgs('users').returns({
            select: Sinon.stub().returnsThis(),
            ilike: Sinon.stub().returnsThis(),
            maybeSingle: Sinon.stub().resolves({ data: null, error: null }),
        } as any);

        const response = await supertest(app.server as any)
            .post('/api/v1/auth/password/forgot')
            .send({ email: 'unknown@campus.edu' });

        expect(response.status).toBe(200);
        expect(response.body.message).toContain('6-digit reset code');
    });

    it('POST /password/reset - resets password with valid pin', async () => {
        const passwordCodesTable = {
            select: Sinon.stub().returnsThis(),
            ilike: Sinon.stub().returnsThis(),
            is: Sinon.stub().returnsThis(),
            order: Sinon.stub().returnsThis(),
            limit: Sinon.stub().returnsThis(),
            maybeSingle: Sinon.stub().resolves({
                data: {
                    id: 'code-1',
                    user_id: 'user_123',
                    code_hash: '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92',
                    expires_at: new Date(Date.now() + 10 * 60 * 1000).toISOString(),
                    attempts: 0,
                    consumed_at: null,
                },
                error: null,
            }),
            update: Sinon.stub().returnsThis(),
            eq: Sinon.stub().resolves({ error: null }),
        } as any;

        // sha256("123456")
        passwordCodesTable.maybeSingle = Sinon.stub().resolves({
            data: {
                id: 'code-1',
                user_id: 'user_123',
                code_hash: '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92',
                expires_at: new Date(Date.now() + 10 * 60 * 1000).toISOString(),
                attempts: 0,
                consumed_at: null,
            },
            error: null,
        });

        mockSupabase.from.withArgs('password_reset_codes').returns(passwordCodesTable);
        mockSupabase.auth.admin.updateUserById.resolves({ data: {}, error: null } as any);

        const response = await supertest(app.server as any)
            .post('/api/v1/auth/password/reset')
            .send({ email: 'test@campus.edu', pin: '123456', new_password: 'newpassword123' });

        expect(response.status).toBe(200);
        expect(response.body.message).toBe('Password updated successfully');
        Sinon.assert.calledOnce(mockSupabase.auth.admin.updateUserById);
    });

    it('POST /password/forgot - stores OTP and sends email via Brevo fetch path', async () => {
        process.env.BREVO_API_KEY = 'test-brevo-key';
        process.env.BREVO_FROM_EMAIL = 'no-reply@swift.campus';

        const usersTable = {
            select: Sinon.stub().returnsThis(),
            ilike: Sinon.stub().returnsThis(),
            maybeSingle: Sinon.stub().resolves({
                data: { id: 'user_123', email: 'test@campus.edu' },
                error: null,
            }),
        } as any;

        const passwordCodesTable = {
            update: Sinon.stub().returnsThis(),
            ilike: Sinon.stub().returnsThis(),
            is: Sinon.stub().resolves({ data: null, error: null }),
            insert: Sinon.stub().resolves({ data: null, error: null }),
        } as any;

        mockSupabase.from.withArgs('users').returns(usersTable);
        mockSupabase.from.withArgs('password_reset_codes').returns(passwordCodesTable);

        fetchStub.resolves({
            ok: true,
            status: 201,
            text: async () => '',
        } as any);

        const response = await supertest(app.server as any)
            .post('/api/v1/auth/password/forgot')
            .send({ email: 'test@campus.edu' });

        expect(response.status).toBe(200);
        expect(response.body.message).toContain('6-digit reset code');
        Sinon.assert.calledOnce(fetchStub);
        Sinon.assert.calledOnce(passwordCodesTable.insert);
    });
});
