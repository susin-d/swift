import { requireRole } from '../../../src/middleware/rbac';
import { FastifyReply, FastifyRequest } from 'fastify';
import Sinon from 'sinon';

describe('RBAC Middleware', () => {
    let mockRequest: Partial<FastifyRequest>;
    let mockReply: Partial<FastifyReply>;
    let replyCodeStub: Sinon.SinonStub;
    let replySendStub: Sinon.SinonStub;

    beforeEach(() => {
        replySendStub = Sinon.stub();
        replyCodeStub = Sinon.stub().returns({ send: replySendStub });
        mockReply = {
            code: replyCodeStub as any,
            send: replySendStub as any
        };
    });

    it('should allow access if user has required role', async () => {
        mockRequest = {
            user: { sub: 'admin-uuid', role: 'admin' }
        };
        const middleware = requireRole(['admin']);

        await middleware(mockRequest as FastifyRequest, mockReply as FastifyReply);

        Sinon.assert.notCalled(replyCodeStub);
        Sinon.assert.notCalled(replySendStub);
    });

    it('should allow access if user has one of the required roles', async () => {
        mockRequest = {
            user: { sub: 'vendor-uuid', role: 'vendor' }
        };
        const middleware = requireRole(['admin', 'vendor']);

        await middleware(mockRequest as FastifyRequest, mockReply as FastifyReply);

        Sinon.assert.notCalled(replyCodeStub);
        Sinon.assert.notCalled(replySendStub);
    });

    it('should deny access if user does not have required role', async () => {
        mockRequest = {
            user: { sub: 'user-uuid', role: 'user' }
        };
        const middleware = requireRole(['admin']);

        await middleware(mockRequest as FastifyRequest, mockReply as FastifyReply);

        Sinon.assert.calledWith(replyCodeStub, 403);
        Sinon.assert.calledWith(replySendStub, Sinon.match({
            error: 'Forbidden'
        }));
    });

    it('should deny access if no user is present', async () => {
        mockRequest = {};
        const middleware = requireRole(['admin']);

        await middleware(mockRequest as FastifyRequest, mockReply as FastifyReply);

        Sinon.assert.calledWith(replyCodeStub, 403);
        Sinon.assert.calledWith(replySendStub, Sinon.match({
            error: 'Forbidden'
        }));
    });
});
