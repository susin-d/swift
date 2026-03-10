import { FastifyInstance } from 'fastify';
import { createReview, getVendorReviews } from '../controllers/reviewController';

export const reviewRoutes = async (app: FastifyInstance) => {
    // Public routes
    app.get('/vendor/:vendorId', getVendorReviews);

    // Protected routes
    app.post('/', { preValidation: [app.authenticate] }, createReview);
};
