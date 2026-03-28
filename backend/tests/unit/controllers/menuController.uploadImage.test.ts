import { uploadMenuItemImageEndpoint } from '../../../src/controllers/menuController';
import * as sinon from 'sinon';
import { FastifyRequest, FastifyReply } from 'fastify';

describe('menuController.uploadMenuItemImageEndpoint', () => {
  let mockRequest: Partial<FastifyRequest>;
  let mockReply: Partial<FastifyReply>;
  let replyStub: any;

  beforeEach(() => {
    replyStub = {
      code: sinon.stub().returnsThis(),
      send: sinon.stub(),
    };
    
    mockRequest = {
      user: { sub: 'vendor-123', role: 'vendor' },
      body: {
        imageData: Buffer.alloc(1000).toString('base64'),
        mimeType: 'image/jpeg',
      },
    };

    mockReply = replyStub as any;
  });

  describe('validation', () => {
    it('should return 401 if user not authenticated', async () => {
      mockRequest.user = undefined;
      
      await uploadMenuItemImageEndpoint(mockRequest as FastifyRequest, mockReply as FastifyReply);

      sinon.assert.calledOnce(replyStub.code);
      expect(replyStub.code.firstCall.args[0]).toBe(401);
    });

    it('should return 400 if imageData missing', async () => {
      mockRequest.body = { mimeType: 'image/jpeg' };
      
      await uploadMenuItemImageEndpoint(mockRequest as FastifyRequest, mockReply as FastifyReply);

      sinon.assert.calledOnce(replyStub.code);
      expect(replyStub.code.firstCall.args[0]).toBe(400);
      expect(replyStub.send.firstCall.args[0].error).toBe('bad_request');
      expect(replyStub.send.firstCall.args[0].message).toContain('imageData');
    });

    it('should return 400 if mimeType missing', async () => {
      mockRequest.body = { imageData: Buffer.alloc(1000).toString('base64') };
      
      await uploadMenuItemImageEndpoint(mockRequest as FastifyRequest, mockReply as FastifyReply);

      sinon.assert.calledOnce(replyStub.code);
      expect(replyStub.code.firstCall.args[0]).toBe(400);
      expect(replyStub.send.firstCall.args[0].error).toBe('bad_request');
      expect(replyStub.send.firstCall.args[0].message).toContain('mimeType');
    });

    it('should return 400 if imageData is not a string', async () => {
      mockRequest.body = {
        imageData: 12345, // Invalid: number instead of string
        mimeType: 'image/jpeg',
      };
      
      await uploadMenuItemImageEndpoint(mockRequest as FastifyRequest, mockReply as FastifyReply);

      sinon.assert.calledOnce(replyStub.code);
      expect(replyStub.code.firstCall.args[0]).toBe(400);
    });

    it('should return 400 if file exceeds 5MB limit', async () => {
      const largeBase64 = Buffer.alloc(6 * 1024 * 1024).toString('base64');
      mockRequest.body = {
        imageData: largeBase64,
        mimeType: 'image/jpeg',
      };
      
      await uploadMenuItemImageEndpoint(mockRequest as FastifyRequest, mockReply as FastifyReply);

      sinon.assert.calledOnce(replyStub.code);
      expect(replyStub.code.firstCall.args[0]).toBe(400);
      expect(replyStub.send.firstCall.args[0].error).toBe('validation_error');
      expect(replyStub.send.firstCall.args[0].message).toContain('too large');
    });

    it('should return 400 if MIME type not allowed', async () => {
      mockRequest.body = {
        imageData: Buffer.alloc(1000).toString('base64'),
        mimeType: 'application/pdf', // Invalid MIME type
      };
      
      await uploadMenuItemImageEndpoint(mockRequest as FastifyRequest, mockReply as FastifyReply);

      sinon.assert.calledOnce(replyStub.code);
      expect(replyStub.code.firstCall.args[0]).toBe(400);
      expect(replyStub.send.firstCall.args[0].error).toBe('validation_error');
      expect(replyStub.send.firstCall.args[0].message).toContain('Invalid MIME type');
    });
  });

  describe('storage error handling', () => {
    it('should return 400 for validation_error', async () => {
      mockRequest.body = {
        imageData: Buffer.alloc(10 * 1024 * 1024).toString('base64'), // > 5MB
        mimeType: 'image/jpeg',
      };
      
      await uploadMenuItemImageEndpoint(mockRequest as FastifyRequest, mockReply as FastifyReply);

      const response = replyStub.send.firstCall.args[0];
      expect(response.error).toBe('validation_error');
    });

    it('should return 400 status code for validation errors', async () => {
      mockRequest.body = {
        imageData: Buffer.alloc(6 * 1024 * 1024).toString('base64'),
        mimeType: 'image/png',
      };
      
      await uploadMenuItemImageEndpoint(mockRequest as FastifyRequest, mockReply as FastifyReply);

      expect(replyStub.code.firstCall.args[0]).toBe(400);
    });
  });
});
