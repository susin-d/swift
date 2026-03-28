import { chatRoutes } from '../../../src/routes/chat';
import * as chatController from '../../../src/controllers/chatController';

describe('chatRoutes', () => {
    it('registers chat and support routes with authentication', async () => {
        const app: any = {
            authenticate: jest.fn(),
            addHook: jest.fn(),
            get: jest.fn(),
            post: jest.fn(),
            patch: jest.fn(),
        };

        await chatRoutes(app);

        expect(app.addHook).toHaveBeenCalledWith('preValidation', app.authenticate);
        expect(app.post).toHaveBeenCalledWith('/api/v1/chat/rooms', chatController.createChatRoom);
        expect(app.get).toHaveBeenCalledWith('/api/v1/chat/rooms/:id/messages', chatController.getChatMessages);
        expect(app.post).toHaveBeenCalledWith('/api/v1/chat/rooms/:id/messages', chatController.sendChatMessage);
        expect(app.get).toHaveBeenCalledWith('/api/v1/support/tickets', chatController.listSupportTickets);
        expect(app.get).toHaveBeenCalledWith('/api/v1/support/tickets/me', chatController.listMySupportTickets);
        expect(app.post).toHaveBeenCalledWith('/api/v1/support/tickets', chatController.createSupportTicket);
        expect(app.patch).toHaveBeenCalledWith('/api/v1/support/tickets/:id', chatController.updateSupportTicket);
    });
});
