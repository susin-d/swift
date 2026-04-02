import Sinon from 'sinon';
import { supabase } from '../../../src/services/supabase';
import { getSpendingAnalytics, getVendorBreakdown } from '../../../src/controllers/analyticsController';

describe('analyticsController — getSpendingAnalytics', () => {
    let fromStub: Sinon.SinonStub;

    beforeEach(() => { fromStub = Sinon.stub(supabase, 'from'); });
    afterEach(() => { Sinon.restore(); });

    it('returns weekly/monthly/top_vendors/total_spent for completed orders', async () => {
        const orders = [
            {
                id: 'ord-1',
                total_amount: 200,
                discount_amount: 20,
                created_at: '2025-01-15T10:00:00.000Z',
                vendor_id: 'v-1',
                vendors: { name: 'Cafe One' },
            },
            {
                id: 'ord-2',
                total_amount: 100,
                discount_amount: 0,
                created_at: '2025-01-20T10:00:00.000Z',
                vendor_id: 'v-1',
                vendors: { name: 'Cafe One' },
            },
        ];

        const orderStub = Sinon.stub().resolves({ data: orders, error: null });
        const eqStatusStub = Sinon.stub().returns({ order: orderStub });
        const eqUserStub = Sinon.stub().returns({ eq: eqStatusStub });
        const selectStub = Sinon.stub().returns({ eq: eqUserStub });
        fromStub.withArgs('orders').returns({ select: selectStub } as any);

        const request: any = { user: { sub: 'u-1' } };
        const reply: any = { send: Sinon.stub() };

        await getSpendingAnalytics(request, reply);

        const sent = reply.send.firstCall.args[0];
        expect(sent).toHaveProperty('weekly');
        expect(sent).toHaveProperty('monthly');
        expect(sent).toHaveProperty('top_vendors');
        expect(sent).toHaveProperty('total_spent');
        expect(sent.total_spent).toBe(280); // 180 + 100
        expect(sent.top_vendors).toHaveLength(1);
        expect(sent.top_vendors[0].vendor_name).toBe('Cafe One');
    });

    it('returns empty aggregations when no orders', async () => {
        const orderStub = Sinon.stub().resolves({ data: [], error: null });
        const eqStatusStub = Sinon.stub().returns({ order: orderStub });
        const eqUserStub = Sinon.stub().returns({ eq: eqStatusStub });
        const selectStub = Sinon.stub().returns({ eq: eqUserStub });
        fromStub.withArgs('orders').returns({ select: selectStub } as any);

        const request: any = { user: { sub: 'u-1' } };
        const reply: any = { send: Sinon.stub() };

        await getSpendingAnalytics(request, reply);

        const sent = reply.send.firstCall.args[0];
        expect(sent.weekly).toEqual([]);
        expect(sent.monthly).toEqual([]);
        expect(sent.top_vendors).toEqual([]);
        expect(sent.total_spent).toBe(0);
    });

    it('throws on supabase error', async () => {
        const orderStub = Sinon.stub().resolves({ data: null, error: new Error('DB fail') });
        const eqStatusStub = Sinon.stub().returns({ order: orderStub });
        const eqUserStub = Sinon.stub().returns({ eq: eqStatusStub });
        const selectStub = Sinon.stub().returns({ eq: eqUserStub });
        fromStub.withArgs('orders').returns({ select: selectStub } as any);

        const request: any = { user: { sub: 'u-1' } };
        const reply: any = { send: Sinon.stub() };

        await expect(getSpendingAnalytics(request, reply)).rejects.toThrow('DB fail');
    });
});

describe('analyticsController — getVendorBreakdown', () => {
    let fromStub: Sinon.SinonStub;

    beforeEach(() => { fromStub = Sinon.stub(supabase, 'from'); });
    afterEach(() => { Sinon.restore(); });

    it('returns vendor breakdown sorted by total descending', async () => {
        const orders = [
            { total_amount: 300, discount_amount: 0, vendor_id: 'v-2', vendors: { name: 'Big Bites' }, created_at: '2025-02-01T00:00:00Z' },
            { total_amount: 100, discount_amount: 10, vendor_id: 'v-1', vendors: { name: 'Small Eats' }, created_at: '2025-01-01T00:00:00Z' },
        ];
        const eqStatusStub = Sinon.stub().resolves({ data: orders, error: null });
        const eqUserStub = Sinon.stub().returns({ eq: eqStatusStub });
        const selectStub = Sinon.stub().returns({ eq: eqUserStub });
        fromStub.withArgs('orders').returns({ select: selectStub } as any);

        const request: any = { user: { sub: 'u-1' } };
        const reply: any = { send: Sinon.stub() };

        await getVendorBreakdown(request, reply);

        const sent = reply.send.firstCall.args[0];
        expect(sent.vendors).toHaveLength(2);
        expect(sent.vendors[0].vendor_name).toBe('Big Bites'); // highest total first
        expect(sent.vendors[1].total).toBe(90); // 100 - 10
    });
});
