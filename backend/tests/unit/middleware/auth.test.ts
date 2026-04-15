import { authMiddlewarePlugin } from '../../../src/middleware/auth';
import Fastify, { FastifyInstance } from 'fastify';
import Sinon from 'sinon';
import { supabase } from '../../../src/services/supabase';
import * as customAuth from '../../../src/services/customAuth';

describe('Auth Middleware', () => {
    let app: FastifyInstance;
    let verifyAccessTokenStub: Sinon.SinonStub;

    beforeEach(async () => {
        app = Fastify();
        verifyAccessTokenStub = Sinon.stub(customAuth, 'verifyAccessToken');
        await app.register(authMiddlewarePlugin);
    });

    afterEach(() => {
        Sinon.restore();
    });

    it('should verify bearer token successfully', async () => {
        verifyAccessTokenStub.returns({ sub: 'user-1', email: 'vendor@test.com', role: 'vendor' });

        Sinon.stub(supabase, 'from')
            .withArgs('auth_accounts')
            .returns({
                select: Sinon.stub().returnsThis(),
                eq: Sinon.stub().returnsThis(),
                maybeSingle: Sinon.stub().resolves({ data: { is_blocked: false }, error: null }),
            } as any)
            .withArgs('users')
            .returns({
                select: Sinon.stub().returnsThis(),
                eq: Sinon.stub().returnsThis(),
                maybeSingle: Sinon.stub().resolves({ data: { id: 'user-1', email: 'vendor@test.com', role: 'vendor' }, error: null }),
            } as any);

        const mockRequest: any = {
            headers: { authorization: 'Bearer token-123' }
        };
        const mockReply: any = {
            code: Sinon.stub().returnsThis(),
            send: Sinon.stub()
        };

        await (app as any).authenticate(mockRequest, mockReply);

        Sinon.assert.calledOnce(verifyAccessTokenStub);
        Sinon.assert.calledWithExactly(verifyAccessTokenStub, 'token-123');
        Sinon.assert.notCalled(mockReply.send);
        expect(mockRequest.user).toEqual({
            sub: 'user-1',
            email: 'vendor@test.com',
            role: 'vendor'
        });
    });

    it('should send unauthorized when token is invalid', async () => {
        verifyAccessTokenStub.throws(new Error('Invalid token'));

        const mockRequest: any = {
            headers: { authorization: 'Bearer bad-token' }
        };
        const mockReply: any = {
            code: Sinon.stub().returnsThis(),
            send: Sinon.stub()
        };

        await (app as any).authenticate(mockRequest, mockReply);

        Sinon.assert.calledOnce(mockReply.code);
        Sinon.assert.calledWithExactly(mockReply.code, 401);
        Sinon.assert.calledOnce(mockReply.send);
    });

    it('should send forbidden when account is blocked', async () => {
        verifyAccessTokenStub.returns({ sub: 'user-2', email: 'blocked@test.com', role: 'admin' });

        Sinon.stub(supabase, 'from')
            .withArgs('auth_accounts')
            .returns({
                select: Sinon.stub().returnsThis(),
                eq: Sinon.stub().returnsThis(),
                maybeSingle: Sinon.stub().resolves({ data: { is_blocked: true }, error: null }),
            } as any)
            .withArgs('users')
            .returns({
                select: Sinon.stub().returnsThis(),
                eq: Sinon.stub().returnsThis(),
                maybeSingle: Sinon.stub().resolves({ data: { id: 'user-2', email: 'blocked@test.com', role: 'admin' }, error: null }),
            } as any);

        const mockRequest: any = {
            headers: { authorization: 'Bearer blocked-token' }
        };
        const mockReply: any = {
            code: Sinon.stub().returnsThis(),
            send: Sinon.stub()
        };

        await (app as any).authenticate(mockRequest, mockReply);

        Sinon.assert.calledWithExactly(mockReply.code, 403);
        Sinon.assert.calledOnce(mockReply.send);
    });
});
