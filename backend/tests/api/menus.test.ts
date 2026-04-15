import supertest from 'supertest';
import { buildApp } from '../../src/app';
import { FastifyInstance } from 'fastify';
import { mockSupabase } from '../mocks/supabaseMock';
import { mockAuthenticate } from '../mocks/authMock';
import Sinon from 'sinon';

describe('API - Menus Controller', () => {
    let app: FastifyInstance;

    beforeAll(async () => {
        app = await buildApp(mockAuthenticate);
        await app.ready();
    });

    afterAll(async () => {
        await app.close();
        Sinon.restore();
    });

    it('GET /vendor/:id - returns public menu items', async () => {
        const mockMenus = [{ id: 'menu_1', category_name: 'Snacks', menu_items: [{ name: 'Samosa' }] }];
        mockSupabase.from.withArgs('menus').returns({
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().resolves({ data: mockMenus, error: null })
        } as any);

        const response = await supertest(app.server).get('/api/v1/menus/vendor/vendor_123');
        expect(response.status).toBe(200);
        expect(response.body).toEqual(mockMenus);
    });

    it('POST / - creates a new menu category (Vendor Only)', async () => {
        const newCategory = { category_name: 'Beverages', vendor_id: 'vendor_456' };
        mockSupabase.from.withArgs('vendors').returns({
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            maybeSingle: Sinon.stub().resolves({ data: { id: 'vendor_456' }, error: null }),
        } as any);
        mockSupabase.from.withArgs('menus').returns({
            insert: Sinon.stub().returnsThis(),
            select: Sinon.stub().returnsThis(),
            single: Sinon.stub().resolves({ data: newCategory, error: null })
        } as any);

        const response = await supertest(app.server as any)
            .post('/api/v1/menus')
            .set('Authorization', 'Bearer valid_vendor_token')
            .send({ category_name: 'Beverages' });

        expect(response.status).toBe(201);
        expect(response.body.category_name).toBe('Beverages');
    });

    it('PATCH /items/:id - updates a menu item', async () => {
        const updatedItem = { name: 'Masala Tea', price: 15 };
        mockSupabase.from.withArgs('vendors').returns({
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            maybeSingle: Sinon.stub().resolves({ data: { id: 'vendor_456' }, error: null }),
        } as any);
        mockSupabase.from.withArgs('menu_items').returns({
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            maybeSingle: Sinon.stub().resolves({ data: { id: 'item_abc', menu_id: 'menu_1' }, error: null }),
            update: Sinon.stub().returnsThis(),
            single: Sinon.stub().resolves({ data: updatedItem, error: null }),
        } as any);
        mockSupabase.from.withArgs('menus').returns({
            select: Sinon.stub().returnsThis(),
            eq: Sinon.stub().returnsThis(),
            maybeSingle: Sinon.stub().resolves({ data: { vendor_id: 'vendor_456' }, error: null }),
        } as any);

        const response = await supertest(app.server as any)
            .patch('/api/v1/menus/items/item_abc')
            .set('Authorization', 'Bearer valid_vendor_token')
            .send({ price: 15 });

        expect(response.status).toBe(200);
        expect(response.body.price).toBe(15);
    });
});
