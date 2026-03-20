import { FastifyInstance } from 'fastify';
import {
    getMyNotifications,
    markNotificationRead,
    registerDeviceToken,
    removeDeviceToken,
} from '../controllers/notificationController';

export const notificationRoutes = async (app: FastifyInstance) => {
    app.addHook('preValidation', app.authenticate);

    app.get('/', getMyNotifications);
    app.patch('/:id/read', markNotificationRead);
    app.post('/device', registerDeviceToken);
    app.delete('/device', removeDeviceToken);
};
