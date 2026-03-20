import { FastifyInstance } from 'fastify';
import { requireUser } from '../middleware/rbac';
import { getMyCart, setMyCart } from '../controllers/cartController';

export const cartRoutes = async (app: FastifyInstance) => {
  app.addHook('preValidation', app.authenticate);
  app.addHook('preHandler', requireUser);

  app.get('/', getMyCart);
  app.patch('/', setMyCart);
};
