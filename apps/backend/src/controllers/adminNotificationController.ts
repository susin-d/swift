import { FastifyReply, FastifyRequest } from 'fastify';
import { broadcastNotification } from '../services/notificationService';

const isPlainObject = (value: unknown): value is Record<string, any> => {
    return !!value && typeof value === 'object' && !Array.isArray(value);
};

export const sendBroadcastNotification = async (request: FastifyRequest, reply: FastifyReply) => {
    const body = (request.body as Record<string, unknown>) || {};
    const title = typeof body.title === 'string' ? body.title.trim() : '';
    const messageBody = typeof body.body === 'string' ? body.body.trim() : '';
    const audience = body.audience === 'user' || body.audience === 'vendor' || body.audience === 'both' ? body.audience : 'both';
    const type = typeof body.type === 'string' && body.type.trim() ? body.type.trim() : 'general';
    const metadata = isPlainObject(body.metadata) ? body.metadata : null;

    if (!title || !messageBody) {
        const error = new Error('Title and body are required') as Error & { statusCode: number };
        error.statusCode = 400;
        throw error;
    }

    const summary = await broadcastNotification({
        audience,
        type,
        title,
        body: messageBody,
        metadata,
    });

    return reply.code(201).send({
        message: audience === 'both' ? 'Notification sent to users and vendors' : `Notification sent to ${audience}s`,
        ...summary,
    });
};