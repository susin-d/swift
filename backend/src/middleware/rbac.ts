import { FastifyReply, FastifyRequest } from 'fastify';

export const requireRole = (roles: string[]) => {
    return async (request: FastifyRequest, reply: FastifyReply) => {
        const user = request.user as any;
        if (!user || !roles.includes(user.role)) {
            const error = new Error('You do not have permission to access this resource') as any;
            error.statusCode = 403;
            error.name = 'Forbidden';
            throw error;
        }
    };
};

export const requireAdmin = requireRole(['admin']);
export const requireVendor = requireRole(['vendor', 'admin']);
