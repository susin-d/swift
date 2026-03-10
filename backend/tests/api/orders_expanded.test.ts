import supertest from 'supertest';
import { buildApp } from '../../src/app';
import { FastifyInstance } from 'fastify';
import { mockSupabase } from '../mocks/supabaseMock';
import { mockAuthenticate } from '../mocks/authMock';
import Sinon from 'sinon';

describe('API - Orders Expansion', () => {
    let app: FastifyInstance;

    beforeAll(async () => {
        app = await buildApp(mockAuthenticate);
        await app.ready();
    });

    afterAll(async () => {
        await app.close();
        Sinon.restore();
    });

    it('POST / - creates order and order items', async () => {
        const mockOrder = { id: 'ord_123', status: 'pending' };

        mockSupabase.from.withArgs('orders').returns({
            insert: Sinon.stub().returnsThis(),
            select: Sinon.stub().returnsThis(),
            single: Sinon.stub().resolves({ data: mockOrder, error: null })
        } as any);

        mockSupabase.from.withArgs('order_items').returns({
            insert: Sinon.stub().resolves({ error: null })
        } as any);

        const response = await supertest(app.server as any)
            .post('/api/v1/orders')
            .set('Authorization', 'Bearer valid_user_token')
            .send({
                vendor_id: 'vendor_456',
                total_amount: 150,
                items: [{ id: 'item_1', quantity: 2, price: 75 }]
            });

        expect(response.status).toBe(201);
        expect(response.body.id).toBe('ord_123');
    });

    it('PATCH /:id/status - updates status (Vendor Only)', async () => {
        const updatedOrder = { id: 'ord_123', status: 'preparing' };
        mockSupabase.from.withArgs('orders').returns({
            update: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            select: Sinon.stub().returnsThis(),
            single: Sinon.stub().resolves({ data: updatedOrder, error: null })
        } as any);

        const response = await supertest(app.server as any)
            .patch('/api/v1/orders/ord_123/status')
            .set('Authorization', 'Bearer valid_vendor_token')
            .send({ status: 'preparing' });

        expect(response.status).toBe(200);
        expect(response.body.status).toBe('preparing');
    });
});
