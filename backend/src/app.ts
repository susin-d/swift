import Fastify from 'fastify';
import cors from '@fastify/cors';
import { setupRoutes } from './routes';
import { authMiddlewarePlugin } from './middleware/auth';

const mapStatusToError = (statusCode: number) => {
    if (statusCode === 400) return 'ValidationError';
    if (statusCode === 401) return 'Unauthorized';
    if (statusCode === 403) return 'Forbidden';
    if (statusCode === 404) return 'NotFound';
    if (statusCode === 409) return 'Conflict';
    return 'InternalServerError';
};

export const buildApp = async (authOverride?: any) => {
    const app = Fastify({ logger: false }); // Disable logger for cleaner test output

    // Plugins
    await app.register(cors, { origin: '*' });

    // Custom auth Plugin
    if (authOverride) {
        app.decorate('authenticate', authOverride);
    } else {
        await app.register(authMiddlewarePlugin);
    }

    // Global Error Handler
    app.setErrorHandler((error: any, request: any, reply: any) => {
        const statusCode = error.statusCode || 500;
        const requestId = request.id ?? 'unknown';
        const clientRequestId = request.headers?.['x-client-request-id'] ?? 'n/a';

        // Log simplified error for monitoring
        console.error(
            `[API Error] reqId=${requestId} clientReqId=${clientRequestId} ${request.method} ${request.url} - Status ${statusCode}:`,
            error.message || String(error)
        );

        let message = error.message || String(error);
        if (statusCode === 404) {
            message = 'Resource not found';
        } else if (statusCode === 400 && error.validation) {
            message = 'Validation failed';
        }
        const isTechnical = message.includes('violates') || message.includes('relation') ||
            message.includes('column') || message.includes('syntax') || message.includes('uuid');

        if (statusCode === 500 || isTechnical) {
            const raw = message;
            message = 'An internal server error occurred';
            if (raw.includes('uuid')) message = 'Invalid ID format';
            else if (raw.includes('RLS') || raw.includes('row-level security')) message = 'Access Denied';
            else if (raw.includes('not-null')) message = 'Required field missing';
            else if (raw.includes('foreign key')) message = 'Referenced record not found';
        }

        return reply.status(statusCode).send({
            error: mapStatusToError(statusCode),
            message: message
        });
    });

    app.setNotFoundHandler((_request, reply) => {
        return reply.status(404).send({
            error: 'NotFound',
            message: 'Resource not found'
        });
    });

    // Routes
    setupRoutes(app);

    return app;
};
