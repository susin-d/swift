import { FastifyInstance, FastifyReply, FastifyRequest } from 'fastify';

/**
 * Mocks the Supabase JWT verifier hook
 * For testing purposes, we inject a dummy user payload based on the headers
 */
export const mockAuthenticate = async (request: FastifyRequest, reply: FastifyReply) => {
    const authHeader = request.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return reply.code(401).send({ error: 'Unauthorized', message: 'Missing or invalid token' });
    }

    const token = authHeader.replace('Bearer ', '');

    if (token === 'expired_token') {
        return reply.code(401).send({ error: 'Unauthorized', message: 'Token expired' });
    }

    // Inject mock user based on role
    if (token === 'valid_user_token') {
        request.user = { sub: 'user_123', role: 'user', email: 'test@campus.edu' };
    } else if (token === 'valid_vendor_token') {
        request.user = { sub: 'vendor_456', role: 'vendor', email: 'canteen@campus.edu' };
    } else if (token === 'valid_admin_token') {
        request.user = { sub: 'admin_789', role: 'admin', email: 'admin@campus.edu' };
    } else {
        return reply.code(401).send({ error: 'Unauthorized', message: 'Invalid token payload' });
    }
};
