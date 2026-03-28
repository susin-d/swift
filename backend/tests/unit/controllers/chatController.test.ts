import {
    __resetChatStateForTests,
    createChatRoom,
    createSupportTicket,
    getChatMessages,
    listMySupportTickets,
    sendChatMessage,
    updateSupportTicket,
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

const requestWithUser = (sub: string, role = 'user') =>
    ({ user: { sub, role } }) as any;

describe('chatController', () => {
    beforeEach(() => {
        __resetChatStateForTests();
    });

    it('creates a room, sends messages, and returns room messages for participants', async () => {
        const createReply = makeReply();
        await createChatRoom(
            {
                ...requestWithUser('user_1'),
                body: { topic: 'Order issue', participantIds: ['agent_1'] },
            } as any,
            createReply as any,
        );

        expect(createReply.statusCode).toBe(201);
        expect(createReply.payload.room.participants).toEqual(expect.arrayContaining(['user_1', 'agent_1']));
        const roomId = createReply.payload.room.id as string;

        const sendReply = makeReply();
        await sendChatMessage(
            {
                ...requestWithUser('agent_1'),
                params: { id: roomId },
                body: { content: 'Hello, how can I help?' },
            } as any,
            sendReply as any,
        );

        expect(sendReply.statusCode).toBe(201);
        expect(sendReply.payload.message.roomId).toBe(roomId);

        const listReply = makeReply();
        await getChatMessages(
            {
                ...requestWithUser('user_1'),
                params: { id: roomId },
                query: { limit: 20 },
            } as any,
            listReply as any,
        );

        expect(listReply.statusCode).toBe(200);
        expect(listReply.payload.messages).toHaveLength(1);
        expect(listReply.payload.messages[0].content).toBe('Hello, how can I help?');
    });

    it('rejects sending a chat message for non-participants', async () => {
        const createReply = makeReply();
        await createChatRoom(
            {
                ...requestWithUser('user_1'),
                body: { participantIds: ['agent_1'] },
            } as any,
            createReply as any,
        );

        const roomId = createReply.payload.room.id as string;
        const sendReply = makeReply();
        await sendChatMessage(
            {
                ...requestWithUser('intruder'),
                params: { id: roomId },
                body: { content: 'should fail' },
            } as any,
            sendReply as any,
        );

        expect(sendReply.statusCode).toBe(403);
        expect(sendReply.payload.error).toBe('Forbidden');
    });

    it('supports support-ticket create, list-my, and owner close workflow', async () => {
        const createReply = makeReply();
        await createSupportTicket(
            {
                ...requestWithUser('user_1'),
                body: {
                    subject: 'Missing item',
                    description: 'My combo meal is missing the drink.',
                    priority: 'high',
                },
            } as any,
            createReply as any,
        );

        expect(createReply.statusCode).toBe(201);
        expect(createReply.payload.ticket.status).toBe('open');
        const ticketId = createReply.payload.ticket.id as string;

        const mineReply = makeReply();
        await listMySupportTickets(requestWithUser('user_1') as any, mineReply as any);
        expect(mineReply.statusCode).toBe(200);
        expect(mineReply.payload.tickets).toHaveLength(1);

        const closeReply = makeReply();
        await updateSupportTicket(
            {
                ...requestWithUser('user_1'),
                params: { id: ticketId },
                body: { status: 'closed', resolutionNote: 'Issue resolved by support.' },
            } as any,
            closeReply as any,
        );

        expect(closeReply.statusCode).toBe(200);
        expect(closeReply.payload.ticket.status).toBe('closed');
        expect(closeReply.payload.ticket.resolutionNote).toBe('Issue resolved by support.');
    });
});
