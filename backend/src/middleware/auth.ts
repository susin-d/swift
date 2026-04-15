import fp from 'fastify-plugin';
import { FastifyInstance, FastifyReply, FastifyRequest } from 'fastify';
import { supabase } from '../services/supabase';
import { verifyAccessToken } from '../services/customAuth';

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

            const decoded = verifyAccessToken(token);

            if (!decoded.sub) {
                return reply.code(401).send({
                    error: 'Unauthorized',
                    message: 'Invalid or expired token'
                });
            }

            const { data: account, error: accountError } = await supabase
                .from('auth_accounts')
                .select('is_blocked')
                .eq('user_id', decoded.sub)
                .maybeSingle();

            const { data: userRow } = await supabase
                .from('users')
                .select('id, email, role')
                .eq('id', decoded.sub)
                .maybeSingle();

            if (accountError || !userRow) {
                return reply.code(401).send({
                    error: 'Unauthorized',
                    message: 'Invalid or expired token'
                });
            }

            const isBlocked = Boolean((account as any)?.is_blocked);
            const isBanned = false;

            if (isBlocked || isBanned) {
                return reply.code(403).send({
                    error: 'Forbidden',
                    message: 'Account is blocked. Contact support.'
                });
            }

            request.user = {
                sub: userRow.id,
                email: userRow.email,
                role: userRow.role || decoded.role || 'user'
            };
        } catch (_err) {
            reply.code(401).send({
                error: 'Unauthorized',
                message: 'Authentication failed'
            });
        }
    });
});
