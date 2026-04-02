import Sinon from 'sinon';
import { supabase } from '../../../src/services/supabase';
import {
    listAdminPromos,
    createAdminPromo,
    updateAdminPromo,
    deleteAdminPromo,
} from '../../../src/controllers/promoAdminController';

describe('promoAdminController — listAdminPromos', () => {
    let fromStub: Sinon.SinonStub;

    beforeEach(() => { fromStub = Sinon.stub(supabase, 'from'); });
    afterEach(() => { Sinon.restore(); });

    it('returns paginated promos with meta', async () => {
        const promos = [{ id: 'p-1', code: 'SAVE10', discount_type: 'percent', discount_value: 10 }];
        const rangeStub = Sinon.stub().resolves({ data: promos, error: null, count: 1 });
        const orderStub = Sinon.stub().returns({ range: rangeStub });
        const selectStub = Sinon.stub().returns({ order: orderStub });
        fromStub.withArgs('promotions').returns({ select: selectStub } as any);

        const request: any = { query: { page: '1', per_page: '10' } };
        const reply: any = { send: Sinon.stub() };

        await listAdminPromos(request, reply);

        const sent = reply.send.firstCall.args[0];
        expect(sent).toHaveProperty('promos');
        expect(sent).toHaveProperty('meta');
        expect(sent.meta.total).toBe(1);
        expect(sent.meta.total_pages).toBe(1);
    });
});

describe('promoAdminController — createAdminPromo', () => {
    let fromStub: Sinon.SinonStub;

    beforeEach(() => { fromStub = Sinon.stub(supabase, 'from'); });
    afterEach(() => { Sinon.restore(); });

    it('returns 400 when code is missing', async () => {
        const request: any = { body: { code: '', discount_type: 'fixed', discount_value: 50 } };
        const reply: any = { code: Sinon.stub().returnsThis(), send: Sinon.stub() };

        await createAdminPromo(request, reply);

        Sinon.assert.calledWithExactly(reply.code, 400);
        Sinon.assert.calledWithMatch(reply.send, { error: 'MissingCode' });
    });

    it('returns 400 for invalid discount_type', async () => {
        const request: any = { body: { code: 'PROMO', discount_type: 'invalid', discount_value: 10 } };
        const reply: any = { code: Sinon.stub().returnsThis(), send: Sinon.stub() };

        await createAdminPromo(request, reply);

        Sinon.assert.calledWithExactly(reply.code, 400);
        Sinon.assert.calledWithMatch(reply.send, { error: 'InvalidDiscountType' });
    });

    it('returns 400 for zero discount_value', async () => {
        const request: any = { body: { code: 'PROMO', discount_type: 'percent', discount_value: 0 } };
        const reply: any = { code: Sinon.stub().returnsThis(), send: Sinon.stub() };

        await createAdminPromo(request, reply);

        Sinon.assert.calledWithExactly(reply.code, 400);
        Sinon.assert.calledWithMatch(reply.send, { error: 'InvalidValue' });
    });

    it('returns 409 on duplicate code (PG unique violation)', async () => {
        const singleStub = Sinon.stub().resolves({ data: null, error: { code: '23505', message: 'duplicate key' } });
        const selectStub = Sinon.stub().returns({ single: singleStub });
        const insertStub = Sinon.stub().returns({ select: selectStub });
        fromStub.withArgs('promotions').returns({ insert: insertStub } as any);

        const request: any = { body: { code: 'SAVE10', discount_type: 'percent', discount_value: 10 } };
        const reply: any = { code: Sinon.stub().returnsThis(), send: Sinon.stub() };

        await createAdminPromo(request, reply);

        Sinon.assert.calledWithExactly(reply.code, 409);
        Sinon.assert.calledWithMatch(reply.send, { error: 'Conflict' });
    });

    it('creates promo and returns 201 with data', async () => {
        const promo = { id: 'p-1', code: 'NEWCODE', discount_type: 'fixed', discount_value: 50, is_active: true };
        const singleStub = Sinon.stub().resolves({ data: promo, error: null });
        const selectStub = Sinon.stub().returns({ single: singleStub });
        const insertStub = Sinon.stub().returns({ select: selectStub });
        fromStub.withArgs('promotions').returns({ insert: insertStub } as any);

        const request: any = { body: { code: 'NEWCODE', discount_type: 'fixed', discount_value: 50 } };
        const reply: any = { code: Sinon.stub().returnsThis(), send: Sinon.stub() };

        await createAdminPromo(request, reply);

        Sinon.assert.calledWithExactly(reply.code, 201);
        Sinon.assert.calledWithMatch(reply.send, { code: 'NEWCODE' });
    });
});

describe('promoAdminController — updateAdminPromo', () => {
    let fromStub: Sinon.SinonStub;

    beforeEach(() => { fromStub = Sinon.stub(supabase, 'from'); });
    afterEach(() => { Sinon.restore(); });

    it('returns 400 when no valid fields provided', async () => {
        const request: any = { params: { id: 'p-1' }, body: { unknown_field: 'value' } };
        const reply: any = { code: Sinon.stub().returnsThis(), send: Sinon.stub() };

        await updateAdminPromo(request, reply);

        Sinon.assert.calledWithExactly(reply.code, 400);
        Sinon.assert.calledWithMatch(reply.send, { error: 'NoUpdates' });
    });

    it('updates promo and returns updated record', async () => {
        const updated = { id: 'p-1', code: 'SAVE20', discount_value: 20, is_active: true };
        const singleStub = Sinon.stub().resolves({ data: updated, error: null });
        const selectStub = Sinon.stub().returns({ single: singleStub });
        const eqStub = Sinon.stub().returns({ select: selectStub });
        const updateStub = Sinon.stub().returns({ eq: eqStub });
        fromStub.withArgs('promotions').returns({ update: updateStub } as any);

        const request: any = { params: { id: 'p-1' }, body: { discount_value: 20 } };
        const reply: any = { send: Sinon.stub() };

        await updateAdminPromo(request, reply);

        Sinon.assert.calledWithMatch(reply.send, { discount_value: 20 });
    });
});

describe('promoAdminController — deleteAdminPromo', () => {
    let fromStub: Sinon.SinonStub;

    beforeEach(() => { fromStub = Sinon.stub(supabase, 'from'); });
    afterEach(() => { Sinon.restore(); });

    it('soft-deletes promo by setting is_active=false', async () => {
        const eqStub = Sinon.stub().resolves({ error: null });
        const updateStub = Sinon.stub().returns({ eq: eqStub });
        fromStub.withArgs('promotions').returns({ update: updateStub } as any);

        const request: any = { params: { id: 'p-1' } };
        const reply: any = { send: Sinon.stub() };

        await deleteAdminPromo(request, reply);

        Sinon.assert.calledWithMatch(reply.send, { message: 'Promo deactivated' });
        const updateArgs = updateStub.firstCall.args[0];
        expect(updateArgs).toMatchObject({ is_active: false });
    });
});
