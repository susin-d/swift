import {
    createChatRoom,
    createSupportTicket,
    getChatMessages,
} from '../../../src/controllers/chatController';

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

describe('chatController validation', () => {
    it('rejects creating a chat room when no second participant is provided', async () => {
        const reply = makeReply();

        await createChatRoom(
            {
                user: { sub: 'user-1', role: 'user' },
                body: { topic: 'Support', participantIds: [] },
            } as any,
            reply as any,
        );

        expect(reply.statusCode).toBe(400);
        expect(reply.payload).toEqual({
            error: 'ValidationError',
            message: 'At least one participant in addition to the creator is required',
        });
    });

    it('requires authentication for support ticket creation', async () => {
        const reply = makeReply();

        await createSupportTicket(
            {
                body: {
                    subject: 'Missing item',
                    description: 'Drink was missing from my order',
                    priority: 'high',
                },
            } as any,
            reply as any,
        );

        expect(reply.statusCode).toBe(401);
        expect(reply.payload.error).toBe('Unauthorized');
    });

    it('requires authentication for reading chat messages', async () => {
        const reply = makeReply();

        await getChatMessages(
            {
                params: { id: 'room-id' },
                query: { limit: 20 },
            } as any,
            reply as any,
        );

        expect(reply.statusCode).toBe(401);
        expect(reply.payload.error).toBe('Unauthorized');
    });
});
