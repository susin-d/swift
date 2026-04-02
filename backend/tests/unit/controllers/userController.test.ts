import Sinon from 'sinon';
import { supabase } from '../../../src/services/supabase';
import {
    requestAccountDeletion,
    cancelAccountDeletion,
    confirmAccountDeletion,
    getUserPreferences,
    updateUserPreferences,
} from '../../../src/controllers/userController';

describe('userController — requestAccountDeletion', () => {
    let fromStub: Sinon.SinonStub;

    beforeEach(() => { fromStub = Sinon.stub(supabase, 'from'); });
    afterEach(() => { Sinon.restore(); });

    it('creates a deletion request and returns message + expires_at', async () => {
        const deleteStub = Sinon.stub().returns({
            eq: Sinon.stub().returns({ is: Sinon.stub().resolves({ error: null }) }),
        });
        const insertStub = Sinon.stub().resolves({ error: null });

        fromStub.withArgs('deletion_requests')
            .onFirstCall().returns({ delete: deleteStub } as any)
            .onSecondCall().returns({ insert: insertStub } as any);

        const request: any = { user: { sub: 'u-1' } };
        const reply: any = { send: Sinon.stub() };

        await requestAccountDeletion(request, reply);

        const sent = reply.send.firstCall.args[0];
        expect(sent).toHaveProperty('message');
        expect(sent).toHaveProperty('expires_at');
    });
});

describe('userController — cancelAccountDeletion', () => {
    let fromStub: Sinon.SinonStub;

    beforeEach(() => { fromStub = Sinon.stub(supabase, 'from'); });
    afterEach(() => { Sinon.restore(); });

    it('deletes pending requests and confirms cancellation', async () => {
        const isStub = Sinon.stub().resolves({ error: null });
        const eqStub = Sinon.stub().returns({ is: isStub });
        const deleteStub = Sinon.stub().returns({ eq: eqStub });
        fromStub.withArgs('deletion_requests').returns({ delete: deleteStub } as any);

        const request: any = { user: { sub: 'u-1' } };
        const reply: any = { send: Sinon.stub() };

        await cancelAccountDeletion(request, reply);

        Sinon.assert.calledWithMatch(reply.send, { message: 'Account deletion cancelled.' });
    });
});

describe('userController — confirmAccountDeletion', () => {
    let fromStub: Sinon.SinonStub;

    beforeEach(() => { fromStub = Sinon.stub(supabase, 'from'); });
    afterEach(() => { Sinon.restore(); });

    it('returns 400 when token is missing', async () => {
        const request: any = { user: { sub: 'u-1' }, body: {} };
        const reply: any = { code: Sinon.stub().returnsThis(), send: Sinon.stub() };

        await confirmAccountDeletion(request, reply);

        Sinon.assert.calledWithExactly(reply.code, 400);
        Sinon.assert.calledWithMatch(reply.send, { error: 'MissingToken' });
    });

    it('returns 404 when no matching deletion request found', async () => {
        const singleStub = Sinon.stub().resolves({ data: null, error: new Error('not found') });
        const isStub = Sinon.stub().returns({ single: singleStub });
        const eq2Stub = Sinon.stub().returns({ is: isStub });
        const eq1Stub = Sinon.stub().returns({ eq: eq2Stub });
        const selectStub = Sinon.stub().returns({ eq: eq1Stub });
        fromStub.withArgs('deletion_requests').returns({ select: selectStub } as any);

        const request: any = { user: { sub: 'u-1' }, body: { token: 'badtoken' } };
        const reply: any = { code: Sinon.stub().returnsThis(), send: Sinon.stub() };

        await confirmAccountDeletion(request, reply);

        Sinon.assert.calledWithExactly(reply.code, 404);
    });

    it('returns 400 for expired token', async () => {
        const past = new Date(Date.now() - 1000).toISOString();
        const req = { expires_at: past, token: 'tok-abc' };
        const singleStub = Sinon.stub().resolves({ data: req, error: null });
        const isStub = Sinon.stub().returns({ single: singleStub });
        const eq2Stub = Sinon.stub().returns({ is: isStub });
        const eq1Stub = Sinon.stub().returns({ eq: eq2Stub });
        const selectStub = Sinon.stub().returns({ eq: eq1Stub });
        fromStub.withArgs('deletion_requests').returns({ select: selectStub } as any);

        const request: any = { user: { sub: 'u-1' }, body: { token: 'tok-abc' } };
        const reply: any = { code: Sinon.stub().returnsThis(), send: Sinon.stub() };

        await confirmAccountDeletion(request, reply);

        Sinon.assert.calledWithExactly(reply.code, 400);
        Sinon.assert.calledWithMatch(reply.send, { error: 'TokenExpired' });
    });
});

describe('userController — getUserPreferences', () => {
    let fromStub: Sinon.SinonStub;

    beforeEach(() => { fromStub = Sinon.stub(supabase, 'from'); });
    afterEach(() => { Sinon.restore(); });

    it('returns upserted user preferences', async () => {
        const prefs = { user_id: 'u-1', allergies: [], dietary_tags: [] };
        const singleStub = Sinon.stub().resolves({ data: prefs, error: null });
        const selectStub = Sinon.stub().returns({ single: singleStub });
        const upsertStub = Sinon.stub().returns({ select: selectStub });
        fromStub.withArgs('user_preferences').returns({ upsert: upsertStub } as any);

        const request: any = { user: { sub: 'u-1' } };
        const reply: any = { send: Sinon.stub() };

        await getUserPreferences(request, reply);

        Sinon.assert.calledWithMatch(reply.send, { user_id: 'u-1' });
    });
});

describe('userController — updateUserPreferences', () => {
    let fromStub: Sinon.SinonStub;

    beforeEach(() => { fromStub = Sinon.stub(supabase, 'from'); });
    afterEach(() => { Sinon.restore(); });

    it('updates preferences and returns saved data', async () => {
        const prefs = { user_id: 'u-1', allergies: ['nuts'], dietary_tags: ['vegan'], cuisine_blacklist: [] };
        const singleStub = Sinon.stub().resolves({ data: prefs, error: null });
        const selectStub = Sinon.stub().returns({ single: singleStub });
        const upsertStub = Sinon.stub().returns({ select: selectStub });
        fromStub.withArgs('user_preferences').returns({ upsert: upsertStub } as any);

        const request: any = {
            user: { sub: 'u-1' },
            body: { allergies: ['nuts'], dietary_tags: ['vegan'] },
        };
        const reply: any = { send: Sinon.stub() };

        await updateUserPreferences(request, reply);

        Sinon.assert.calledWithMatch(reply.send, { allergies: ['nuts'] });
    });
});
