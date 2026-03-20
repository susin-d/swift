import { FastifyInstance } from 'fastify';
import { authRoutes } from './auth';
import { orderRoutes } from './orders';
import { vendorOpsRoutes } from './vendor-ops';
import { menuRoutes } from './menus';
import { paymentRoutes } from './payments';
import { adminRoutes } from './admin';

import { deliveryRoutes } from './delivery';
import { publicRoutes } from './public';
import { reviewRoutes } from './reviews';
import { addressRoutes } from './addresses';
import { cartRoutes } from './cart';
import { contractsRoutes } from './contracts';
import { notificationRoutes } from './notifications';
import { promoRoutes } from './promos';
import { campusRoutes } from './campus';
import { classSessionRoutes } from './class-sessions';

export const setupRoutes = (app: FastifyInstance) => {
    app.get('/health', async () => ({ status: 'ok', timestamp: new Date().toISOString() }));
    app.get('/api/health', async () => ({ status: 'ok', timestamp: new Date().toISOString() }));

    app.register(authRoutes, { prefix: '/api/v1/auth' });
    app.register(adminRoutes, { prefix: '/api/v1/admin' });
    app.register(orderRoutes, { prefix: '/api/v1/orders' });
    app.register(vendorOpsRoutes, { prefix: '/api/v1/vendor-ops' });
    app.register(menuRoutes, { prefix: '/api/v1/menus' });
    app.register(paymentRoutes, { prefix: '/api/v1/payments' });
    app.register(deliveryRoutes, { prefix: '/api/v1/delivery' });
    app.register(publicRoutes, { prefix: '/api/v1/public' });
    app.register(reviewRoutes, { prefix: '/api/v1/reviews' });
    app.register(addressRoutes, { prefix: '/api/v1/addresses' });
    app.register(cartRoutes, { prefix: '/api/v1/cart' });
    app.register(contractsRoutes, { prefix: '/api/v1/contracts' });
    app.register(notificationRoutes, { prefix: '/api/v1/notifications' });
    app.register(promoRoutes, { prefix: '/api/v1/promos' });
    app.register(campusRoutes, { prefix: '/api/v1' });
    app.register(classSessionRoutes, { prefix: '/api/v1/class-sessions' });
};
