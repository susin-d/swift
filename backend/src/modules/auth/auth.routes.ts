import { FastifyInstance } from 'fastify';
import {
    loginHandler,
    getMeHandler,
    registerHandler,
    updateMeHandler,
    acceptStaffOnboardingInviteHandler,
    forgotPasswordHandler,
    resetPasswordWithOtpHandler,
} from './auth.controller';

export const authRoutes = async (app: FastifyInstance) => {
    app.post('/register', registerHandler);
    app.post('/session', loginHandler);
    app.post('/password/forgot', forgotPasswordHandler);
    app.post('/password/reset', resetPasswordWithOtpHandler);
    app.get('/me', { preValidation: [app.authenticate] }, getMeHandler);
    app.patch('/me', { preValidation: [app.authenticate] }, updateMeHandler);
    app.post('/staff/onboarding/accept', { preValidation: [app.authenticate] }, acceptStaffOnboardingInviteHandler);
};
