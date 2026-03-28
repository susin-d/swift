import supertest from 'supertest';
import { FastifyInstance } from 'fastify';
import { buildApp } from '../../src/app';
import { mockAuthenticate } from '../mocks/authMock';
import { mockSupabase } from '../mocks/supabaseMock';
import Sinon from 'sinon';

describe('API - Cart', () => {
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

  it('GET /api/v1/cart returns empty cart for new user', async () => {
    mockSupabase.from.withArgs('user_carts').returns({
      select: Sinon.stub().returnsThis(),
      eq: Sinon.stub().returnsThis(),
      maybeSingle: Sinon.stub().resolves({ data: null, error: null })
    } as any);

    const response = await supertest(app.server as any)
      .get('/api/v1/cart')
      .set('Authorization', 'Bearer valid_user_token');

    expect(response.status).toBe(200);
    expect(response.body).toEqual({ items: [] });
  });

  it('PATCH /api/v1/cart with valid items updates cart', async () => {
    const items = [
      { item: { id: 'item1', name: 'Pizza', price: 100 }, quantity: 2 }
    ];
    mockSupabase.from.withArgs('user_carts').returns({
      upsert: Sinon.stub().returnsThis(),
      select: Sinon.stub().returnsThis(),
      single: Sinon.stub().resolves({ data: { items }, error: null })
    } as any);

    const response = await supertest(app.server as any)
      .patch('/api/v1/cart')
      .set('Authorization', 'Bearer valid_user_token')
      .send({ items });

    expect(response.status).toBe(200);
    expect(response.body.items).toEqual(items);
  });

  it('PATCH /api/v1/cart with missing items array returns 400', async () => {
    const response = await supertest(app.server as any)
      .patch('/api/v1/cart')
      .set('Authorization', 'Bearer valid_user_token')
      .send({});

    expect(response.status).toBe(400);
    expect(response.body.error).toBeDefined();
    expect(response.body.message).toMatch(/items array is required/i);
  });

  it('PATCH /api/v1/cart with invalid item structure returns 200 with filtered items', async () => {
    // Only valid items should be persisted
    const items = [
      { item: { id: 'item1', name: 'Pizza', price: 100 }, quantity: 2 },
      { item: {}, quantity: 0 }, // invalid
      { item: null, quantity: 1 }, // invalid
      { item: { id: '' }, quantity: 1 }, // invalid
    ];
    const filtered = [
      { item: { id: 'item1', name: 'Pizza', price: 100 }, quantity: 2 }
    ];
    mockSupabase.from.withArgs('user_carts').returns({
      upsert: Sinon.stub().returnsThis(),
      select: Sinon.stub().returnsThis(),
      single: Sinon.stub().resolves({ data: { items: filtered }, error: null })
    } as any);

    const response = await supertest(app.server as any)
      .patch('/api/v1/cart')
      .set('Authorization', 'Bearer valid_user_token')
      .send({ items });

    expect(response.status).toBe(200);
    expect(response.body.items).toEqual(filtered);
  });
});
