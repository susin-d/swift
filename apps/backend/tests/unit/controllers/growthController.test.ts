import {
    addLoyaltyPoints,
    createSubscription,
    redeemReferralCode,
    requestRefund,
} from '../../../src/controllers/growthController';

type MockReply = {
    statusCode: number;
    payload: any;
    code: (status: number) => MockReply;
    send: (payload: any) => MockReply;
};

const makeReply = (): MockReply => {
    const reply: MockReply = {
        statusCode: 200,
        payload: null,
        code(status: number) {
            this.statusCode = status;
            return this;
        },
        send(payload: any) {
            this.payload = payload;
            return this;
        },
    };
    return reply;
};

describe('growthController validation', () => {
    it('requires auth for subscription creation', async () => {
        const reply = makeReply();
        await createSubscription({ body: { plan: 'plus' } } as any, reply as any);
        expect(reply.statusCode).toBe(401);
        expect(reply.payload.error).toBe('Unauthorized');
    });

    it('validates required referral code for redeem', async () => {
        const reply = makeReply();
        await redeemReferralCode({ user: { sub: 'user-1', role: 'user' }, body: {} } as any, reply as any);
        expect(reply.statusCode).toBe(400);
        expect(reply.payload.error).toBe('ValidationError');
    });

    it('blocks non-admin loyalty mutation', async () => {
        const reply = makeReply();
        await addLoyaltyPoints({ user: { sub: 'user-1', role: 'user' }, body: { points: 0 } } as any, reply as any);
        expect(reply.statusCode).toBe(403);
        expect(reply.payload.error).toBe('Forbidden');
    });

    it('validates loyalty payload for admin mutation', async () => {
        const reply = makeReply();
        await addLoyaltyPoints({ user: { sub: 'admin-1', role: 'admin' }, body: { points: 0, userId: 'user-1' } } as any, reply as any);
        expect(reply.statusCode).toBe(400);
        expect(reply.payload.error).toBe('ValidationError');
    });

    it('validates refund payload', async () => {
        const reply = makeReply();
        await requestRefund(
            {
                user: { sub: 'user-1', role: 'user' },
                params: { id: '' },
                body: { reason: '' },
            } as any,
            reply as any,
        );
        expect(reply.statusCode).toBe(400);
        expect(reply.payload.error).toBe('ValidationError');
    });
});
