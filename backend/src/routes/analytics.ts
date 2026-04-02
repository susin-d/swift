import { FastifyInstance } from 'fastify';
import { requireUser } from '../middleware/rbac';
import { getSpendingAnalytics, getVendorBreakdown } from '../controllers/analyticsController';

export const analyticsRoutes = async (app: FastifyInstance) => {
    app.addHook('preValidation', app.authenticate);
    app.get('/spending', { preHandler: [requireUser] }, getSpendingAnalytics);
    app.get('/vendors', { preHandler: [requireUser] }, getVendorBreakdown);
};
