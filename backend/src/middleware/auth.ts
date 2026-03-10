import fp from 'fastify-plugin';
import { FastifyInstance, FastifyReply, FastifyRequest } from 'fastify';
import { supabase } from '../services/supabase';

declare module 'fastify' {
    interface FastifyInstance {
        authenticate: (request: FastifyRequest, reply: FastifyReply) => Promise<void>;
    }
    interface FastifyRequest {
        user?: {
            sub: string;
            email?: string;
            role: string;
        };
    }
}

export const authMiddlewarePlugin = fp(async (app: FastifyInstance) => {
    app.decorate('authenticate', async (request: FastifyRequest, reply: FastifyReply) => {
        try {
            const authHeader = request.headers.authorization;
            if (!authHeader) {
                return reply.code(401).send({ error: 'Missing authorization header' });
            }

            const token = authHeader.replace('Bearer ', '');
            console.log('Verifying token:', token.substring(0, 20) + '...');
            const { data: { user }, error } = await supabase.auth.getUser(token);

            if (error || !user) {
                console.error('Supabase getUser error detail:', JSON.stringify(error, null, 2));
                return reply.code(401).send({ error: 'Invalid or expired token' });
            }

            console.log('User verified:', user.email);

            // Map Supabase user to request.user for consistency
            request.user = {
                sub: user.id,
                email: user.email,
                role: user.user_metadata?.role || 'user'
            };
        } catch (err) {
            console.error('Auth middleware catch:', err);
            reply.code(401).send({ error: 'Authentication failed' });
        }
    });
});
