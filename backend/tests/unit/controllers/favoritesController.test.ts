import Sinon from 'sinon';
import { supabase } from '../../../src/services/supabase';
import { getFavorites, addFavorite, removeFavorite } from '../../../src/controllers/favoritesController';

describe('favoritesController — getFavorites', () => {
    let fromStub: Sinon.SinonStub;

    beforeEach(() => { fromStub = Sinon.stub(supabase, 'from'); });
    afterEach(() => { Sinon.restore(); });

    it('returns vendor_ids array for user', async () => {
        const rows = [{ vendor_id: 'v-1' }, { vendor_id: 'v-2' }];
        const eqStub = Sinon.stub().resolves({ data: rows, error: null });
        const selectStub = Sinon.stub().returns({ eq: eqStub });
        fromStub.withArgs('favorites').returns({ select: selectStub } as any);

        const request: any = { user: { sub: 'u-1' } };
        const reply: any = { send: Sinon.stub() };

        await getFavorites(request, reply);

        Sinon.assert.calledWithMatch(reply.send, { vendor_ids: ['v-1', 'v-2'] });
    });

    it('returns empty array when no favorites', async () => {
        const eqStub = Sinon.stub().resolves({ data: [], error: null });
        const selectStub = Sinon.stub().returns({ eq: eqStub });
        fromStub.withArgs('favorites').returns({ select: selectStub } as any);

        const request: any = { user: { sub: 'u-1' } };
        const reply: any = { send: Sinon.stub() };

        await getFavorites(request, reply);

        Sinon.assert.calledWithMatch(reply.send, { vendor_ids: [] });
    });
});

describe('favoritesController — addFavorite', () => {
    let fromStub: Sinon.SinonStub;

    beforeEach(() => { fromStub = Sinon.stub(supabase, 'from'); });
    afterEach(() => { Sinon.restore(); });

    it('upserts then returns updated vendor_ids', async () => {
        const upsertStub = Sinon.stub().resolves({ error: null });
        const rows = [{ vendor_id: 'v-1' }];
        const eqStub = Sinon.stub().resolves({ data: rows, error: null });
        const selectAfterStub = Sinon.stub().returns({ eq: eqStub });

        fromStub.withArgs('favorites')
            .onFirstCall().returns({ upsert: upsertStub } as any)
            .onSecondCall().returns({ select: selectAfterStub } as any);

        const request: any = { user: { sub: 'u-1' }, params: { vendorId: 'v-1' } };
        const reply: any = { send: Sinon.stub() };

        await addFavorite(request, reply);

        Sinon.assert.calledWithMatch(reply.send, { vendor_ids: ['v-1'] });
    });
});

describe('favoritesController — removeFavorite', () => {
    let fromStub: Sinon.SinonStub;

    beforeEach(() => { fromStub = Sinon.stub(supabase, 'from'); });
    afterEach(() => { Sinon.restore(); });

    it('deletes then returns updated vendor_ids', async () => {
        const eq2Stub = Sinon.stub().resolves({ error: null });
        const eq1Stub = Sinon.stub().returns({ eq: eq2Stub });
        const deleteStub = Sinon.stub().returns({ eq: eq1Stub });

        const rows = [{ vendor_id: 'v-2' }];
        const eqStub = Sinon.stub().resolves({ data: rows, error: null });
        const selectAfterStub = Sinon.stub().returns({ eq: eqStub });

        fromStub.withArgs('favorites')
            .onFirstCall().returns({ delete: deleteStub } as any)
            .onSecondCall().returns({ select: selectAfterStub } as any);

        const request: any = { user: { sub: 'u-1' }, params: { vendorId: 'v-1' } };
        const reply: any = { send: Sinon.stub() };

        await removeFavorite(request, reply);

        Sinon.assert.calledWithMatch(reply.send, { vendor_ids: ['v-2'] });
    });
});
