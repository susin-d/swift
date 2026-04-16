import { FastifyInstance } from 'fastify';
import { getActivePromos, validatePromoCode } from '../controllers/promoController';
import { requireUser } from '../middleware/rbac';

export const promoRoutes = async (app: FastifyInstance) => {
    app.addHook('preValidation', app.authenticate);

    app.get('/active', { preHandler: [requireUser] }, getActivePromos);
    app.post('/validate', { preHandler: [requireUser] }, validatePromoCode);
};
