import supertest from 'supertest';
import { FastifyInstance } from 'fastify';
import { buildApp } from '../../src/app';
import { mockAuthenticate } from '../mocks/authMock';

describe('API - RBAC parity', () => {
    let app: FastifyInstance;

    beforeAll(async () => {
        app = await buildApp(mockAuthenticate);
        await app.ready();
    });

    afterAll(async () => {
        await app.close();
    });

    it('denies vendor tokens on customer order creation', async () => {
        const response = await supertest(app.server as any)
            .post('/api/v1/orders')
            .set('Authorization', 'Bearer valid_vendor_token')
            .send({ vendor_id: 'vendor_1', total_amount: 250, items: [] });

        expect(response.status).toBe(403);
        expect(response.body).toMatchObject({
            error: 'Forbidden',
            message: 'You do not have permission to access this resource'
        });
    });

    it('denies admin tokens on customer order history', async () => {
        const response = await supertest(app.server as any)
            .get('/api/v1/orders/me')
            .set('Authorization', 'Bearer valid_admin_token');

        expect(response.status).toBe(403);
    });

    it('denies vendor tokens on customer addresses', async () => {
        const response = await supertest(app.server as any)
            .get('/api/v1/addresses')
            .set('Authorization', 'Bearer valid_vendor_token');

        expect(response.status).toBe(403);
    });

    it('denies vendor tokens on payment creation', async () => {
        const response = await supertest(app.server as any)
            .post('/api/v1/payments/create-order')
            .set('Authorization', 'Bearer valid_vendor_token')
            .send({ amount: 500 });

        expect(response.status).toBe(403);
    });

    it('denies vendor tokens on customer reviews', async () => {
        const response = await supertest(app.server as any)
            .post('/api/v1/reviews')
            .set('Authorization', 'Bearer valid_vendor_token')
            .send({ order_id: 'order_1', rating: 5 });

        expect(response.status).toBe(403);
    });

    it('denies customer tokens on delivery location updates', async () => {
        const response = await supertest(app.server as any)
            .post('/api/v1/delivery/location')
            .set('Authorization', 'Bearer valid_user_token')
            .send({ order_id: 'order_1', lat: 12.3, lng: 45.6 });

        expect(response.status).toBe(403);
    });

    it('allows vendor tokens through delivery RBAC and reaches controller validation', async () => {
        const response = await supertest(app.server as any)
            .post('/api/v1/delivery/location')
            .set('Authorization', 'Bearer valid_vendor_token')
            .send({});

        expect(response.status).toBe(400);
        expect(response.body).toMatchObject({
            error: 'ValidationError',
            message: 'Order ID, lat, and lng are required'
        });
    });
});