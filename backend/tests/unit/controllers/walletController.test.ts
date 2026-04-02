import Sinon from 'sinon';
import { supabase } from '../../../src/services/supabase';
import {
    getWalletBalance,
    topupWallet,
    getWalletTransactions,
    debitWallet,
} from '../../../src/controllers/walletController';

describe('walletController — getWalletBalance', () => {
    let fromStub: Sinon.SinonStub;

    beforeEach(() => { fromStub = Sinon.stub(supabase, 'from'); });
    afterEach(() => { Sinon.restore(); });

    it('returns wallet balance for user', async () => {
        const wallet = { balance: 500, currency: 'INR', user_id: 'u-1' };
        const singleStub = Sinon.stub().resolves({ data: wallet, error: null });
        const selectStub = Sinon.stub().returns({ single: singleStub });
        const upsertStub = Sinon.stub().returns({ select: selectStub });
        fromStub.withArgs('wallets').returns({ upsert: upsertStub } as any);

        const request: any = { user: { sub: 'u-1' } };
        const reply: any = { send: Sinon.stub() };

        await getWalletBalance(request, reply);

        Sinon.assert.calledWithMatch(reply.send, { balance: 500, currency: 'INR' });
    });

    it('throws on supabase error', async () => {
        const singleStub = Sinon.stub().resolves({ data: null, error: new Error('DB error') });
        const selectStub = Sinon.stub().returns({ single: singleStub });
        const upsertStub = Sinon.stub().returns({ select: selectStub });
        fromStub.withArgs('wallets').returns({ upsert: upsertStub } as any);

        const request: any = { user: { sub: 'u-1' } };
        const reply: any = { send: Sinon.stub() };

        await expect(getWalletBalance(request, reply)).rejects.toThrow('DB error');
    });
});

describe('walletController — topupWallet', () => {
    let fromStub: Sinon.SinonStub;

    beforeEach(() => { fromStub = Sinon.stub(supabase, 'from'); });
    afterEach(() => { Sinon.restore(); });

    it('returns 400 for invalid amount (zero)', async () => {
        const request: any = { user: { sub: 'u-1' }, body: { amount: 0 } };
        const reply: any = { code: Sinon.stub().returnsThis(), send: Sinon.stub() };

        await topupWallet(request, reply);

        Sinon.assert.calledWithExactly(reply.code, 400);
        Sinon.assert.calledWithMatch(reply.send, { error: 'InvalidAmount' });
    });

    it('returns 400 for amount exceeding 10000', async () => {
        const request: any = { user: { sub: 'u-1' }, body: { amount: 10001 } };
        const reply: any = { code: Sinon.stub().returnsThis(), send: Sinon.stub() };

        await topupWallet(request, reply);

        Sinon.assert.calledWithExactly(reply.code, 400);
    });

    it('tops up wallet and returns updated balance', async () => {
        const wallet = { balance: 600, currency: 'INR', user_id: 'u-1' };

        // upsert call (no return needed)
        const upsertOnly = Sinon.stub().resolves({ data: null, error: null });

        // select current balance
        const currentSingle = Sinon.stub().resolves({ data: { balance: 500 }, error: null });
        const currentEq = Sinon.stub().returns({ single: currentSingle });
        const currentSelect = Sinon.stub().returns({ eq: currentEq });

        // update with new balance
        const updatedSingle = Sinon.stub().resolves({ data: wallet, error: null });
        const updatedSelect = Sinon.stub().returns({ single: updatedSingle });
        const updatedEq = Sinon.stub().returns({ select: updatedSelect });
        const updateStub = Sinon.stub().returns({ eq: updatedEq });

        // transaction insert
        const insertStub = Sinon.stub().resolves({ error: null });

        fromStub.withArgs('wallets')
            .onFirstCall().returns({ upsert: upsertOnly } as any)
            .onSecondCall().returns({ select: currentSelect } as any)
            .onThirdCall().returns({ update: updateStub } as any);
        fromStub.withArgs('wallet_transactions').returns({ insert: insertStub } as any);

        const request: any = { user: { sub: 'u-1' }, body: { amount: 100 } };
        const reply: any = { send: Sinon.stub() };

        await topupWallet(request, reply);

        Sinon.assert.calledWithMatch(reply.send, { balance: 600 });
    });
});

describe('walletController — debitWallet', () => {
    let fromStub: Sinon.SinonStub;

    beforeEach(() => { fromStub = Sinon.stub(supabase, 'from'); });
    afterEach(() => { Sinon.restore(); });

    it('returns 400 for invalid amount', async () => {
        const request: any = { user: { sub: 'u-1' }, body: { amount: -5 } };
        const reply: any = { code: Sinon.stub().returnsThis(), send: Sinon.stub() };

        await debitWallet(request, reply);

        Sinon.assert.calledWithExactly(reply.code, 400);
        Sinon.assert.calledWithMatch(reply.send, { error: 'InvalidAmount' });
    });

    it('returns 400 for insufficient balance', async () => {
        const singleStub = Sinon.stub().resolves({ data: { balance: 50 }, error: null });
        const eqStub = Sinon.stub().returns({ single: singleStub });
        const selectStub = Sinon.stub().returns({ eq: eqStub });
        fromStub.withArgs('wallets').returns({ select: selectStub } as any);

        const request: any = { user: { sub: 'u-1' }, body: { amount: 100 } };
        const reply: any = { code: Sinon.stub().returnsThis(), send: Sinon.stub() };

        await debitWallet(request, reply);

        Sinon.assert.calledWithExactly(reply.code, 400);
        Sinon.assert.calledWithMatch(reply.send, { error: 'InsufficientBalance' });
    });
});

describe('walletController — getWalletTransactions', () => {
    let fromStub: Sinon.SinonStub;

    beforeEach(() => { fromStub = Sinon.stub(supabase, 'from'); });
    afterEach(() => { Sinon.restore(); });

    it('returns paginated transactions', async () => {
        const txns = [{ id: 'tx-1', type: 'topup', amount: 100 }];
        const rangeStub = Sinon.stub().resolves({ data: txns, error: null, count: 1 });
        const orderStub = Sinon.stub().returns({ range: rangeStub });
        const eqStub = Sinon.stub().returns({ order: orderStub });
        const selectStub = Sinon.stub().returns({ eq: eqStub });
        fromStub.withArgs('wallet_transactions').returns({ select: selectStub } as any);

        const request: any = { user: { sub: 'u-1' }, query: { page: '1', per_page: '10' } };
        const reply: any = { send: Sinon.stub() };

        await getWalletTransactions(request, reply);

        const sent = reply.send.firstCall.args[0];
        expect(sent).toHaveProperty('transactions');
        expect(sent).toHaveProperty('meta');
        expect(sent.meta.page).toBe(1);
        expect(sent.meta.per_page).toBe(10);
    });
});
