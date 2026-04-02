import { FastifyInstance } from 'fastify';
import { requireUser } from '../middleware/rbac';
import {
    requestAccountDeletion,
    cancelAccountDeletion,
    confirmAccountDeletion,
    getUserPreferences,
    updateUserPreferences,
} from '../controllers/userController';

export const userRoutes = async (app: FastifyInstance) => {
    app.addHook('preValidation', app.authenticate);
    app.post('/me/delete-request', { preHandler: [requireUser] }, requestAccountDeletion);
    app.delete('/me/delete-request', { preHandler: [requireUser] }, cancelAccountDeletion);
    app.post('/me/delete-confirm', { preHandler: [requireUser] }, confirmAccountDeletion);
    app.get('/me/preferences', { preHandler: [requireUser] }, getUserPreferences);
    app.put('/me/preferences', { preHandler: [requireUser] }, updateUserPreferences);
};
