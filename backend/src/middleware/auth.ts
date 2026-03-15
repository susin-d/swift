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
                return reply.code(401).send({
                    error: 'Unauthorized',
                    message: 'Missing authorization header'
                });
            }

            if (!authHeader.startsWith('Bearer ')) {
                return reply.code(401).send({
                    error: 'Unauthorized',
                    message: 'Invalid authorization header format'
                });
            }

            const token = authHeader.replace('Bearer ', '').trim();
            if (!token) {
                return reply.code(401).send({
                    error: 'Unauthorized',
                    message: 'Missing bearer token'
                });
            }

            const { data: { user }, error } = await supabase.auth.getUser(token);

            if (error || !user) {
                return reply.code(401).send({
                    error: 'Unauthorized',
                    message: 'Invalid or expired token'
                });
            }

            const isBlocked = user.user_metadata?.is_blocked === true;
            const bannedUntilRaw = (user as any).banned_until as string | null | undefined;
            const bannedUntilMs = bannedUntilRaw ? Date.parse(bannedUntilRaw) : Number.NaN;
            const isBanned = Number.isFinite(bannedUntilMs) && bannedUntilMs > Date.now();

            if (isBlocked || isBanned) {
                return reply.code(403).send({
                    error: 'Forbidden',
                    message: 'Account is blocked. Contact support.'
                });
            }

            // Map Supabase user to request.user for consistency
            request.user = {
                sub: user.id,
                email: user.email,
                role: user.user_metadata?.role || 'user'
            };
        } catch (_err) {
            reply.code(401).send({
                error: 'Unauthorized',
                message: 'Authentication failed'
            });
        }
    });
});
