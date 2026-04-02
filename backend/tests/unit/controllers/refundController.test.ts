import Sinon from 'sinon';
import { supabase } from '../../../src/services/supabase';
import { requestRefund, getMyRefunds, resolveRefund } from '../../../src/controllers/refundController';

describe('refundController — requestRefund', () => {
    let fromStub: Sinon.SinonStub;

    beforeEach(() => { fromStub = Sinon.stub(supabase, 'from'); });
    afterEach(() => { Sinon.restore(); });

    it('returns 400 when reason is too short', async () => {
        const request: any = { user: { sub: 'u-1' }, params: { id: 'ord-1' }, body: { reason: 'short' } };
        const reply: any = { code: Sinon.stub().returnsThis(), send: Sinon.stub() };

        await requestRefund(request, reply);

        Sinon.assert.calledWithExactly(reply.code, 400);
        Sinon.assert.calledWithMatch(reply.send, { error: 'InvalidReason' });
    });

    it('returns 404 when order not found', async () => {
        const singleStub = Sinon.stub().resolves({ data: null, error: new Error('not found') });
        const eqUserStub = Sinon.stub().returns({ single: singleStub });
        const eqIdStub = Sinon.stub().returns({ eq: eqUserStub });
        const selectStub = Sinon.stub().returns({ eq: eqIdStub });
        fromStub.withArgs('orders').returns({ select: selectStub } as any);

        const request: any = {
            user: { sub: 'u-1' },
            params: { id: 'ord-1' },
            body: { reason: 'The food was completely wrong and inedible.' },
        };
        const reply: any = { code: Sinon.stub().returnsThis(), send: Sinon.stub() };

        await requestRefund(request, reply);

        Sinon.assert.calledWithExactly(reply.code, 404);
    });

    it('returns 400 when order status is not completed or cancelled', async () => {
        const order = { id: 'ord-1', status: 'pending', user_id: 'u-1' };
        const singleStub = Sinon.stub().resolves({ data: order, error: null });
        const eqUserStub = Sinon.stub().returns({ single: singleStub });
        const eqIdStub = Sinon.stub().returns({ eq: eqUserStub });
        const selectStub = Sinon.stub().returns({ eq: eqIdStub });
        fromStub.withArgs('orders').returns({ select: selectStub } as any);

        const request: any = {
            user: { sub: 'u-1' },
            params: { id: 'ord-1' },
            body: { reason: 'The food was completely wrong and inedible.' },
        };
        const reply: any = { code: Sinon.stub().returnsThis(), send: Sinon.stub() };

        await requestRefund(request, reply);

        Sinon.assert.calledWithExactly(reply.code, 400);
        Sinon.assert.calledWithMatch(reply.send, { error: 'InvalidStatus' });
    });

    it('returns 409 when a pending refund already exists', async () => {
        const order = { id: 'ord-1', status: 'completed', user_id: 'u-1' };
        const singleStub = Sinon.stub().resolves({ data: order, error: null });
        const eqUserStub = Sinon.stub().returns({ single: singleStub });
        const eqIdStub = Sinon.stub().returns({ eq: eqUserStub });
        const selectOrders = Sinon.stub().returns({ eq: eqIdStub });
        fromStub.withArgs('orders').returns({ select: selectOrders } as any);

        const maybeSingleStub = Sinon.stub().resolves({ data: { id: 'ref-1' }, error: null });
        const eqStatusStub = Sinon.stub().returns({ maybeSingle: maybeSingleStub });
        const eqUserRefundStub = Sinon.stub().returns({ eq: eqStatusStub });
        const eqOrderRefundStub = Sinon.stub().returns({ eq: eqUserRefundStub });
        const selectRefunds = Sinon.stub().returns({ eq: eqOrderRefundStub });
        fromStub.withArgs('refund_requests').returns({ select: selectRefunds } as any);

        const request: any = {
            user: { sub: 'u-1' },
            params: { id: 'ord-1' },
            body: { reason: 'The food was completely wrong and inedible.' },
        };
        const reply: any = { code: Sinon.stub().returnsThis(), send: Sinon.stub() };

        await requestRefund(request, reply);

        Sinon.assert.calledWithExactly(reply.code, 409);
        Sinon.assert.calledWithMatch(reply.send, { error: 'Conflict' });
    });
});

describe('refundController — getMyRefunds', () => {
    let fromStub: Sinon.SinonStub;

    beforeEach(() => { fromStub = Sinon.stub(supabase, 'from'); });
    afterEach(() => { Sinon.restore(); });

    it('returns paginated refund list', async () => {
        const refunds = [{ id: 'ref-1', status: 'pending' }];
        const rangeStub = Sinon.stub().resolves({ data: refunds, error: null, count: 1 });
        const orderStub = Sinon.stub().returns({ range: rangeStub });
        const eqStub = Sinon.stub().returns({ order: orderStub });
        const selectStub = Sinon.stub().returns({ eq: eqStub });
        fromStub.withArgs('refund_requests').returns({ select: selectStub } as any);

        const request: any = { user: { sub: 'u-1' }, query: { page: '1', per_page: '10' } };
        const reply: any = { send: Sinon.stub() };

        await getMyRefunds(request, reply);

        const sent = reply.send.firstCall.args[0];
        expect(sent).toHaveProperty('refunds');
        expect(sent).toHaveProperty('meta');
        expect(sent.meta.total).toBe(1);
    });
});

describe('refundController — resolveRefund', () => {
    let fromStub: Sinon.SinonStub;

    beforeEach(() => { fromStub = Sinon.stub(supabase, 'from'); });
    afterEach(() => { Sinon.restore(); });

    it('returns 400 for invalid status', async () => {
        const request: any = { params: { id: 'ref-1' }, body: { status: 'unknown', admin_note: 'Test note' } };
        const reply: any = { code: Sinon.stub().returnsThis(), send: Sinon.stub() };

        await resolveRefund(request, reply);

        Sinon.assert.calledWithExactly(reply.code, 400);
        Sinon.assert.calledWithMatch(reply.send, { error: 'InvalidStatus' });
    });

    it('returns 400 when admin_note is empty', async () => {
        const request: any = { params: { id: 'ref-1' }, body: { status: 'approved', admin_note: '' } };
        const reply: any = { code: Sinon.stub().returnsThis(), send: Sinon.stub() };

        await resolveRefund(request, reply);

        Sinon.assert.calledWithExactly(reply.code, 400);
        Sinon.assert.calledWithMatch(reply.send, { error: 'MissingNote' });
    });

    it('approves a refund and returns updated record', async () => {
        const updated = { id: 'ref-1', status: 'approved', admin_note: 'Legitimate claim' };
        const singleStub = Sinon.stub().resolves({ data: updated, error: null });
        const selectStub = Sinon.stub().returns({ single: singleStub });
        const eqStub = Sinon.stub().returns({ select: selectStub });
        const updateStub = Sinon.stub().returns({ eq: eqStub });
        fromStub.withArgs('refund_requests').returns({ update: updateStub } as any);

        const request: any = {
            params: { id: 'ref-1' },
            body: { status: 'approved', admin_note: 'Legitimate claim' },
        };
        const reply: any = { send: Sinon.stub() };

        await resolveRefund(request, reply);

        Sinon.assert.calledWithMatch(reply.send, { status: 'approved' });
    });
});
