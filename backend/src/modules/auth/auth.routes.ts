import { FastifyInstance } from 'fastify';
import { loginHandler, getMeHandler, registerHandler, updateMeHandler } from './auth.controller';

export const authRoutes = async (app: FastifyInstance) => {
    app.post('/register', registerHandler);
    app.post('/session', loginHandler);
    app.get('/me', { preValidation: [app.authenticate] }, getMeHandler);
    app.patch('/me', { preValidation: [app.authenticate] }, updateMeHandler);
};
