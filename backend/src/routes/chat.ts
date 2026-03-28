import { FastifyInstance } from 'fastify';
import * as chatController from '../controllers/chatController';

export async function chatRoutes(app: FastifyInstance) {
  app.addHook('preValidation', app.authenticate);

  app.post('/api/v1/chat/rooms', chatController.createChatRoom);
  app.get('/api/v1/chat/rooms/:id/messages', chatController.getChatMessages);
  app.post('/api/v1/chat/rooms/:id/messages', chatController.sendChatMessage);

  app.get('/api/v1/support/tickets', chatController.listSupportTickets);
  app.get('/api/v1/support/tickets/me', chatController.listMySupportTickets);
  app.post('/api/v1/support/tickets', chatController.createSupportTicket);
  app.patch('/api/v1/support/tickets/:id', chatController.updateSupportTicket);
}
