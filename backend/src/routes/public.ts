import { FastifyInstance } from 'fastify';
import { getAllVendors } from '../controllers/vendorController';
import { globalSearch } from '../controllers/searchController';

export const publicRoutes = async (app: FastifyInstance) => {
    app.get('/vendors', getAllVendors);
    app.get('/search', globalSearch);
};
