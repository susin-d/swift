import { authMiddlewarePlugin } from '../../../src/middleware/auth';
import Fastify, { FastifyInstance } from 'fastify';
import Sinon from 'sinon';
import { supabase } from '../../../src/services/supabase';

describe('Auth Middleware', () => {
    let app: FastifyInstance;
    let getUserStub: Sinon.SinonStub;

    beforeEach(async () => {
        app = Fastify();
        getUserStub = Sinon.stub(supabase.auth, 'getUser');
        await app.register(authMiddlewarePlugin);
    });

    afterEach(() => {
        Sinon.restore();
    });

    it('should verify bearer token successfully', async () => {
        getUserStub.resolves({
            data: {
                user: {
                    id: 'user-1',
                    email: 'vendor@test.com',
                    user_metadata: { role: 'vendor' }
                }
            },
            error: null
        });

        const mockRequest: any = {
            headers: { authorization: 'Bearer token-123' }
        };
        const mockReply: any = {
            code: Sinon.stub().returnsThis(),
            send: Sinon.stub()
        };

        await (app as any).authenticate(mockRequest, mockReply);

        Sinon.assert.calledOnce(getUserStub);
        Sinon.assert.calledWithExactly(getUserStub, 'token-123');
        Sinon.assert.notCalled(mockReply.send);
        expect(mockRequest.user).toEqual({
            sub: 'user-1',
            email: 'vendor@test.com',
            role: 'vendor'
        });
    });

    it('should send unauthorized when token is invalid', async () => {
        getUserStub.resolves({
            data: { user: null },
            error: { message: 'Invalid token' }
        });

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
        getUserStub.resolves({
            data: {
                user: {
                    id: 'user-2',
                    email: 'blocked@test.com',
                    user_metadata: { role: 'admin', is_blocked: true }
                }
            },
            error: null
        });

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
