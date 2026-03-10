import Fastify from 'fastify';
import cors from '@fastify/cors';
import { setupRoutes } from './routes';
import { authMiddlewarePlugin } from './middleware/auth';

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

        // Log simplified error for monitoring
        console.error(`[API Error] ${request.method} ${request.url} - Status ${statusCode}:`, error.message || String(error));

        let message = error.message || String(error);
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
            error: (statusCode === 403 ? 'Forbidden' : (statusCode === 401 ? 'Unauthorized' : 'InternalServerError')),
            message: message
        });
    });

    // Routes
    setupRoutes(app);

    return app;
};
