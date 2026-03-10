import { authMiddlewarePlugin } from '../../../src/middleware/auth';
import Fastify, { FastifyInstance } from 'fastify';
import Sinon from 'sinon';

describe('Auth Middleware', () => {
    let app: FastifyInstance;

    beforeEach(async () => {
        app = Fastify();
        // Mock jwt
        app.decorate('jwtVerify', Sinon.stub().resolves());
        await app.register(authMiddlewarePlugin);
    });

    it('should verify JWT successfully', async () => {
        const jwtVerifyStub = Sinon.stub().resolves();
        const mockRequest: any = {
            jwtVerify: jwtVerifyStub
        };
        const mockReply: any = {
            send: Sinon.stub()
        };

        await (app as any).authenticate(mockRequest, mockReply);

        Sinon.assert.calledOnce(jwtVerifyStub);
        Sinon.assert.notCalled(mockReply.send);
    });

    it('should send error if JWT verification fails', async () => {
        const error = new Error('Unauthorized');
        const jwtVerifyStub = Sinon.stub().rejects(error);
        const mockRequest: any = {
            jwtVerify: jwtVerifyStub
        };
        const mockReply: any = {
            send: Sinon.stub()
        };

        await (app as any).authenticate(mockRequest, mockReply);

        Sinon.assert.calledOnce(jwtVerifyStub);
        Sinon.assert.calledWith(mockReply.send, error);
    });
});
