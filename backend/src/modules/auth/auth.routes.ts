import { FastifyInstance } from 'fastify';
import { loginHandler, getMeHandler, registerHandler, updateMeHandler, acceptStaffOnboardingInviteHandler } from './auth.controller';

export const authRoutes = async (app: FastifyInstance) => {
    app.post('/register', registerHandler);
    app.post('/session', loginHandler);
    app.get('/me', { preValidation: [app.authenticate] }, getMeHandler);
    app.patch('/me', { preValidation: [app.authenticate] }, updateMeHandler);
    app.post('/staff/onboarding/accept', { preValidation: [app.authenticate] }, acceptStaffOnboardingInviteHandler);
};
