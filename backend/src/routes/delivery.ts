import { FastifyInstance } from 'fastify';
import { updateLocation, getLocation } from '../controllers/deliveryController';

export const deliveryRoutes = async (app: FastifyInstance) => {
    app.addHook('preValidation', app.authenticate);

    // Webhook for updating location
    app.post('/location', updateLocation);

    // Endpoint for getting location
    app.get('/:orderId/location', getLocation);
};
