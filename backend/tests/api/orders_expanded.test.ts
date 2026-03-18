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

    beforeEach(() => {
        mockSupabase.from.resetHistory();
        mockSupabase.from.resetBehavior();
    });

    it('POST / - creates order and order items', async () => {
        const mockOrder = { id: 'ord_123', status: 'pending', created_at: new Date().toISOString() };

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
        expect(response.body.eta).toEqual(
            expect.objectContaining({
                min_minutes: expect.any(Number),
                max_minutes: expect.any(Number),
                confidence: expect.any(String),
            })
        );
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
        expect(response.body.eta).toEqual(
            expect.objectContaining({
                min_minutes: expect.any(Number),
                max_minutes: expect.any(Number),
                confidence: expect.any(String),
            })
        );
    });

    it('GET /me - returns eta and pacing fields for each order', async () => {
        const orders = [
            {
                id: 'ord_456',
                status: 'accepted',
                created_at: new Date(Date.now() - 10 * 60 * 1000).toISOString(),
                total_amount: 220,
                order_items: [{ id: 'oi_1' }],
                vendors: { name: 'Campus Canteen' },
            },
        ];

        mockSupabase.from.withArgs('orders').returns({
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            order: Sinon.stub().resolves({ data: orders, error: null }),
        } as any);

        const response = await supertest(app.server as any)
            .get('/api/v1/orders/me')
            .set('Authorization', 'Bearer valid_user_token');

        expect(response.status).toBe(200);
        expect(Array.isArray(response.body)).toBe(true);
        expect(response.body[0]).toEqual(
            expect.objectContaining({
                id: 'ord_456',
                eta: expect.objectContaining({
                    min_minutes: expect.any(Number),
                    max_minutes: expect.any(Number),
                    confidence: expect.any(String),
                }),
                pacing: expect.objectContaining({
                    elapsed_minutes: expect.any(Number),
                    target_prep_minutes: expect.any(Number),
                    recommended_prep_minutes: expect.any(Number),
                    sla_risk: expect.any(String),
                    pace_label: expect.any(String),
                }),
            })
        );
    });
});
