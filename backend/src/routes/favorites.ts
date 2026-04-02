import { FastifyInstance } from 'fastify';
import { requireUser } from '../middleware/rbac';
import { getFavorites, addFavorite, removeFavorite } from '../controllers/favoritesController';

export const favoritesRoutes = async (app: FastifyInstance) => {
    app.addHook('preValidation', app.authenticate);
    app.get('/', { preHandler: [requireUser] }, getFavorites);
    app.post('/:vendorId', { preHandler: [requireUser] }, addFavorite);
    app.delete('/:vendorId', { preHandler: [requireUser] }, removeFavorite);
};
