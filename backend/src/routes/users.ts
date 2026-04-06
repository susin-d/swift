import { FastifyInstance } from 'fastify';
import { requireUser } from '../middleware/rbac';
import {
    cancelAccountDeletion,
    getAccountDeletionStatus,
    requestAccountDeletion,
} from '../controllers/userAccountController';

export const userRoutes = async (app: FastifyInstance) => {
    app.addHook('preValidation', app.authenticate);
    app.get('/me/deletion', { preHandler: [requireUser] }, getAccountDeletionStatus as any);
    app.delete('/me', { preHandler: [requireUser] }, requestAccountDeletion as any);
    app.patch('/me/deletion/cancel', { preHandler: [requireUser] }, cancelAccountDeletion as any);
};
