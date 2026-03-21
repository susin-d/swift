import Sinon from 'sinon';
import { supabase } from '../../../src/services/supabase';
import {
    createOrder,
    getMyOrders,
    updateOrderStatus,
    getVendorOrders,
} from '../../../src/controllers/orderController';

const NOW_ISO = '2025-01-01T10:00:00.000Z';

describe('Order Controller — createOrder', () => {
    let fromStub: Sinon.SinonStub;

    beforeEach(() => {
        fromStub = Sinon.stub(supabase, 'from');
    });

    afterEach(() => {
        Sinon.restore();
    });

    it('inserts order + items and returns 201 with eta field', async () => {
        const order = { id: 'ord-1', vendor_id: 'v-1', user_id: 'u-1', total_amount: 150, status: 'pending', created_at: NOW_ISO };

        const orderSingleStub = Sinon.stub().resolves({ data: order, error: null });
        const orderSelectStub = Sinon.stub().returns({ single: orderSingleStub });
        const orderInsertStub = Sinon.stub().returns({ select: orderSelectStub });

        const itemsInsertStub = Sinon.stub().resolves({ error: null });

        fromStub.onFirstCall().returns({ insert: orderInsertStub } as any);
        fromStub.onSecondCall().returns({ insert: itemsInsertStub } as any);

        const request: any = {
            user: { sub: 'u-1' },
            body: {
                vendor_id: 'v-1',
                total_amount: 150,
                items: [{ id: 'mi-1', quantity: 2, price: 75 }],
            },
        };
        const reply: any = { code: Sinon.stub().returnsThis(), send: Sinon.stub() };

        await createOrder(request, reply);

        Sinon.assert.calledWithExactly(reply.code, 201);
        const sent = reply.send.firstCall.args[0];
        expect(sent).toHaveProperty('eta');
        expect(sent.eta).toHaveProperty('min_minutes');
        expect(sent.eta).toHaveProperty('max_minutes');
        expect(sent.eta).toHaveProperty('confidence');
        expect(sent.id).toBe('ord-1');
    });

    it('throws when order insert fails', async () => {
        const dbError = new Error('insert error');
        const orderSingleStub = Sinon.stub().resolves({ data: null, error: dbError });
        const orderSelectStub = Sinon.stub().returns({ single: orderSingleStub });
        const orderInsertStub = Sinon.stub().returns({ select: orderSelectStub });

        fromStub.onFirstCall().returns({ insert: orderInsertStub } as any);

        const request: any = {
            user: { sub: 'u-1' },
            body: { vendor_id: 'v-1', total_amount: 150, items: [] },
        };
        const reply: any = { code: Sinon.stub().returnsThis(), send: Sinon.stub() };

        await expect(createOrder(request, reply)).rejects.toThrow('insert error');
    });

    it('throws when order_items insert fails', async () => {
        const order = { id: 'ord-1', vendor_id: 'v-1', user_id: 'u-1', total_amount: 75, status: 'pending', created_at: NOW_ISO };

        const orderSingleStub = Sinon.stub().resolves({ data: order, error: null });
        const orderSelectStub = Sinon.stub().returns({ single: orderSingleStub });
        const orderInsertStub = Sinon.stub().returns({ select: orderSelectStub });

        const itemsError = new Error('items insert error');
        const itemsInsertStub = Sinon.stub().resolves({ error: itemsError });

        fromStub.onFirstCall().returns({ insert: orderInsertStub } as any);
        fromStub.onSecondCall().returns({ insert: itemsInsertStub } as any);

        const request: any = {
            user: { sub: 'u-1' },
            body: { vendor_id: 'v-1', total_amount: 75, items: [{ id: 'mi-1', quantity: 1, price: 75 }] },
        };
        const reply: any = { code: Sinon.stub().returnsThis(), send: Sinon.stub() };

        await expect(createOrder(request, reply)).rejects.toThrow('items insert error');
    });
});

describe('Order Controller — getMyOrders', () => {
    let fromStub: Sinon.SinonStub;

    beforeEach(() => {
        fromStub = Sinon.stub(supabase, 'from');
    });

    afterEach(() => {
        Sinon.restore();
    });

    it('returns orders with eta and pacing fields for authenticated user', async () => {
        const orders = [
            { id: 'ord-1', user_id: 'u-1', status: 'accepted', total_amount: 120, created_at: NOW_ISO, order_items: [] },
        ];

        const orderStub = Sinon.stub().resolves({ data: orders, error: null });
        const eqStub = Sinon.stub().returns({ order: orderStub });
        const selectStub = Sinon.stub().returns({ eq: eqStub });

        fromStub.withArgs('orders').returns({ select: selectStub } as any);

        const request: any = { user: { sub: 'u-1' } };
        const reply: any = { send: Sinon.stub() };

        await getMyOrders(request, reply);

        const sent = reply.send.firstCall.args[0] as any[];
        expect(Array.isArray(sent)).toBe(true);
        expect(sent[0]).toHaveProperty('eta');
        expect(sent[0]).toHaveProperty('pacing');
        expect(sent[0].eta).toHaveProperty('confidence');
    });

    it('returns empty array when no orders found', async () => {
        const orderStub = Sinon.stub().resolves({ data: null, error: null });
        const eqStub = Sinon.stub().returns({ order: orderStub });
        const selectStub = Sinon.stub().returns({ eq: eqStub });

        fromStub.withArgs('orders').returns({ select: selectStub } as any);

        const request: any = { user: { sub: 'u-2' } };
        const reply: any = { send: Sinon.stub() };

        await getMyOrders(request, reply);

        expect(reply.send.firstCall.args[0]).toEqual([]);
    });
});

describe('Order Controller — updateOrderStatus', () => {
    let fromStub: Sinon.SinonStub;

    beforeEach(() => {
        fromStub = Sinon.stub(supabase, 'from');
    });

    afterEach(() => {
        Sinon.restore();
    });

    it('updates order status and returns record with eta field', async () => {
        const updated = { id: 'ord-1', status: 'preparing', total_amount: 80, created_at: NOW_ISO };

        const singleStub = Sinon.stub().resolves({ data: updated, error: null });
        const selectStub = Sinon.stub().returns({ single: singleStub });
        const eqStub = Sinon.stub().returns({ select: selectStub });
        const updateStub = Sinon.stub().returns({ eq: eqStub });

        fromStub.withArgs('orders').returns({ update: updateStub } as any);

        const request: any = { params: { id: 'ord-1' }, body: { status: 'preparing' } };
        const reply: any = { send: Sinon.stub() };

        await updateOrderStatus(request, reply);

        Sinon.assert.calledOnce(updateStub);
        const sent = reply.send.firstCall.args[0];
        expect(sent).toHaveProperty('eta');
        expect(sent.eta.confidence).toBe('medium'); // 'preparing' → medium
    });

    it('eta confidence is high for accepted status', async () => {
        const updated = { id: 'ord-2', status: 'accepted', created_at: NOW_ISO };

        const singleStub = Sinon.stub().resolves({ data: updated, error: null });
        const selectStub = Sinon.stub().returns({ single: singleStub });
        const eqStub = Sinon.stub().returns({ select: selectStub });
        const updateStub = Sinon.stub().returns({ eq: eqStub });

        fromStub.withArgs('orders').returns({ update: updateStub } as any);

        const request: any = { params: { id: 'ord-2' }, body: { status: 'accepted' } };
        const reply: any = { send: Sinon.stub() };

        await updateOrderStatus(request, reply);

        expect(reply.send.firstCall.args[0].eta.confidence).toBe('high');
    });

    it('eta confidence is low for cancelled status', async () => {
        const updated = { id: 'ord-3', status: 'cancelled', created_at: NOW_ISO };

        const singleStub = Sinon.stub().resolves({ data: updated, error: null });
        const selectStub = Sinon.stub().returns({ single: singleStub });
        const eqStub = Sinon.stub().returns({ select: selectStub });
        const updateStub = Sinon.stub().returns({ eq: eqStub });

        fromStub.withArgs('orders').returns({ update: updateStub } as any);

        const request: any = { params: { id: 'ord-3' }, body: { status: 'cancelled' } };
        const reply: any = { send: Sinon.stub() };

        await updateOrderStatus(request, reply);

        expect(reply.send.firstCall.args[0].eta.confidence).toBe('low');
    });

    it('throws on Supabase error', async () => {
        const dbError = new Error('update failed');

        const singleStub = Sinon.stub().resolves({ data: null, error: dbError });
        const selectStub = Sinon.stub().returns({ single: singleStub });
        const eqStub = Sinon.stub().returns({ select: selectStub });
        const updateStub = Sinon.stub().returns({ eq: eqStub });

        fromStub.withArgs('orders').returns({ update: updateStub } as any);

        const request: any = { params: { id: 'ord-x' }, body: { status: 'ready' } };
        const reply: any = { send: Sinon.stub() };

        await expect(updateOrderStatus(request, reply)).rejects.toThrow('update failed');
    });
});

describe('Order Controller — getVendorOrders', () => {
    let fromStub: Sinon.SinonStub;

    beforeEach(() => {
        fromStub = Sinon.stub(supabase, 'from');
    });

    afterEach(() => {
        Sinon.restore();
    });

    it('returns vendor orders with eta field', async () => {
        const vendor = { id: 'v-1' };
        const orders = [
            { id: 'ord-1', vendor_id: 'v-1', status: 'pending', total_amount: 200, created_at: NOW_ISO, order_items: [{ id: 'oi-1' }] },
        ];

        const vendorSingleStub = Sinon.stub().resolves({ data: vendor, error: null });
        const vendorEqStub = Sinon.stub().returns({ single: vendorSingleStub });
        const vendorSelectStub = Sinon.stub().returns({ eq: vendorEqStub });

        const orderResult = Sinon.stub().resolves({ data: orders, error: null });
        const orderEqStub = Sinon.stub().returns({ order: orderResult });
        const orderSelectStub = Sinon.stub().returns({ eq: orderEqStub });

        fromStub.onFirstCall().returns({ select: vendorSelectStub } as any);
        fromStub.onSecondCall().returns({ select: orderSelectStub } as any);

        const request: any = { user: { sub: 'owner-1' } };
        const reply: any = { send: Sinon.stub() };

        await getVendorOrders(request, reply);

        const sent = reply.send.firstCall.args[0] as any[];
        expect(Array.isArray(sent)).toBe(true);
        expect(sent[0]).toHaveProperty('eta');
        expect(sent[0].eta.confidence).toBe('high'); // 'pending' → high
    });

    it('throws 404 when vendor not found', async () => {
        const vendorSingleStub = Sinon.stub().resolves({ data: null, error: new Error('not found') });
        const vendorEqStub = Sinon.stub().returns({ single: vendorSingleStub });
        const vendorSelectStub = Sinon.stub().returns({ eq: vendorEqStub });

        fromStub.onFirstCall().returns({ select: vendorSelectStub } as any);

        const request: any = { user: { sub: 'unknown-owner' } };
        const reply: any = { send: Sinon.stub() };

        const err = await getVendorOrders(request, reply).catch((e: any) => e);
        expect(err.message).toBe('Vendor not found');
        expect(err.statusCode).toBe(404);
    });

    it('returns empty array when vendor has no orders', async () => {
        const vendor = { id: 'v-2' };

        const vendorSingleStub = Sinon.stub().resolves({ data: vendor, error: null });
        const vendorEqStub = Sinon.stub().returns({ single: vendorSingleStub });
        const vendorSelectStub = Sinon.stub().returns({ eq: vendorEqStub });

        const orderResult = Sinon.stub().resolves({ data: null, error: null });
        const orderEqStub = Sinon.stub().returns({ order: orderResult });
        const orderSelectStub = Sinon.stub().returns({ eq: orderEqStub });

        fromStub.onFirstCall().returns({ select: vendorSelectStub } as any);
        fromStub.onSecondCall().returns({ select: orderSelectStub } as any);

        const request: any = { user: { sub: 'owner-2' } };
        const reply: any = { send: Sinon.stub() };

        await getVendorOrders(request, reply);

        expect(reply.send.firstCall.args[0]).toEqual([]);
    });
});
