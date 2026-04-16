import { FastifyInstance } from 'fastify';
import {
    createClassSession,
    deleteClassSession,
    listMyClassSessions,
    updateClassSession,
} from '../controllers/classSessionController';
import { requireUser } from '../middleware/rbac';

export const classSessionRoutes = async (app: FastifyInstance) => {
    app.addHook('preValidation', app.authenticate);

    app.get('/', { preHandler: [requireUser] }, listMyClassSessions);
    app.post('/', { preHandler: [requireUser] }, createClassSession);
    app.patch('/:id', { preHandler: [requireUser] }, updateClassSession);
    app.delete('/:id', { preHandler: [requireUser] }, deleteClassSession);
};
