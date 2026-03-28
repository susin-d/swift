import { FastifyReply, FastifyRequest } from 'fastify';

type ChatRoomStatus = 'active' | 'closed';
type TicketStatus = 'open' | 'in_progress' | 'resolved' | 'closed';
type TicketPriority = 'low' | 'normal' | 'high' | 'urgent';

type ChatRoom = {
    id: string;
    topic: string;
    status: ChatRoomStatus;
    createdBy: string;
    participants: string[];
    createdAt: string;
    updatedAt: string;
};

type ChatMessage = {
    id: string;
    roomId: string;
    senderId: string;
    content: string;
    createdAt: string;
};

type SupportTicket = {
    id: string;
    subject: string;
    description: string;
    priority: TicketPriority;
    status: TicketStatus;
    createdBy: string;
    assigneeId: string | null;
    orderId: string | null;
    resolutionNote: string | null;
    createdAt: string;
    updatedAt: string;
};

const chatRooms = new Map<string, ChatRoom>();
const chatMessages = new Map<string, ChatMessage[]>();
const supportTickets = new Map<string, SupportTicket>();

const nowIso = () => new Date().toISOString();
const makeId = (prefix: string) => `${prefix}_${Date.now()}_${Math.random().toString(36).slice(2, 10)}`;

const ticketStatuses: TicketStatus[] = ['open', 'in_progress', 'resolved', 'closed'];
const ticketPriorities: TicketPriority[] = ['low', 'normal', 'high', 'urgent'];

const sendValidationError = (reply: FastifyReply, message: string) =>
    reply.code(400).send({ error: 'ValidationError', message });

const sendForbidden = (reply: FastifyReply, message: string) =>
    reply.code(403).send({ error: 'Forbidden', message });

const sendNotFound = (reply: FastifyReply, message: string) =>
    reply.code(404).send({ error: 'NotFound', message });

const userFromRequest = (request: FastifyRequest) => request.user as { sub: string; role: string } | undefined;

export const createChatRoom = async (
    request: FastifyRequest<{ Body: { participantIds?: string[]; topic?: string } }>,
    reply: FastifyReply,
) => {
    const user = userFromRequest(request);
    if (!user?.sub) {
        return reply.code(401).send({ error: 'Unauthorized', message: 'Authentication required' });
    }

    const topic = request.body?.topic?.trim() || 'Support conversation';
    const participantIds = Array.isArray(request.body?.participantIds) ? request.body.participantIds : [];
    const participants = Array.from(new Set([user.sub, ...participantIds.filter((id) => typeof id === 'string' && id.trim())]));

    if (participants.length < 2) {
        return sendValidationError(reply, 'At least one participant in addition to the creator is required');
    }
    if (topic.length > 120) {
        return sendValidationError(reply, 'Topic cannot exceed 120 characters');
    }

    const createdAt = nowIso();
    const room: ChatRoom = {
        id: makeId('room'),
        topic,
        status: 'active',
        createdBy: user.sub,
        participants,
        createdAt,
        updatedAt: createdAt,
    };

    chatRooms.set(room.id, room);
    chatMessages.set(room.id, []);
    return reply.code(201).send({ room });
};

export const getChatMessages = async (
    request: FastifyRequest<{ Params: { id: string }; Querystring: { limit?: number } }>,
    reply: FastifyReply,
) => {
    const user = userFromRequest(request);
    if (!user?.sub) {
        return reply.code(401).send({ error: 'Unauthorized', message: 'Authentication required' });
    }

    const room = chatRooms.get(request.params.id);
    if (!room) {
        return sendNotFound(reply, 'Chat room not found');
    }
    if (!room.participants.includes(user.sub) && user.role !== 'admin') {
        return sendForbidden(reply, 'You are not a participant in this chat room');
    }

    const rawLimit = Number(request.query?.limit ?? 50);
    const limit = Number.isFinite(rawLimit) ? Math.max(1, Math.min(rawLimit, 100)) : 50;
    const messages = (chatMessages.get(room.id) ?? []).slice(-limit);
    return reply.send({ roomId: room.id, messages, meta: { count: messages.length, limit } });
};

export const sendChatMessage = async (
    request: FastifyRequest<{ Params: { id: string }; Body: { content?: string } }>,
    reply: FastifyReply,
) => {
    const user = userFromRequest(request);
    if (!user?.sub) {
        return reply.code(401).send({ error: 'Unauthorized', message: 'Authentication required' });
    }

    const room = chatRooms.get(request.params.id);
    if (!room) {
        return sendNotFound(reply, 'Chat room not found');
    }
    if (room.status !== 'active') {
        return sendValidationError(reply, 'Chat room is closed');
    }
    if (!room.participants.includes(user.sub) && user.role !== 'admin') {
        return sendForbidden(reply, 'You are not a participant in this chat room');
    }

    const content = request.body?.content?.trim();
    if (!content) {
        return sendValidationError(reply, 'Message content is required');
    }
    if (content.length > 2000) {
        return sendValidationError(reply, 'Message content cannot exceed 2000 characters');
    }

    const message: ChatMessage = {
        id: makeId('msg'),
        roomId: room.id,
        senderId: user.sub,
        content,
        createdAt: nowIso(),
    };
    const messages = chatMessages.get(room.id) ?? [];
    messages.push(message);
    chatMessages.set(room.id, messages);
    room.updatedAt = nowIso();
    chatRooms.set(room.id, room);

    return reply.code(201).send({ message });
};

export const listSupportTickets = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = userFromRequest(request);
    if (!user?.sub) {
        return reply.code(401).send({ error: 'Unauthorized', message: 'Authentication required' });
    }

    const list = Array.from(supportTickets.values());
    const tickets = user.role === 'admin' ? list : list.filter((ticket) => ticket.createdBy === user.sub);
    return reply.send({ tickets });
};

export const listMySupportTickets = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = userFromRequest(request);
    if (!user?.sub) {
        return reply.code(401).send({ error: 'Unauthorized', message: 'Authentication required' });
    }

    const tickets = Array.from(supportTickets.values()).filter((ticket) => ticket.createdBy === user.sub);
    return reply.send({ tickets });
};

export const createSupportTicket = async (
    request: FastifyRequest<{
        Body: { subject?: string; description?: string; orderId?: string; priority?: TicketPriority };
    }>,
    reply: FastifyReply,
) => {
    const user = userFromRequest(request);
    if (!user?.sub) {
        return reply.code(401).send({ error: 'Unauthorized', message: 'Authentication required' });
    }

    const subject = request.body?.subject?.trim();
    const description = request.body?.description?.trim();
    const priority = request.body?.priority ?? 'normal';
    const orderId = request.body?.orderId?.trim() || null;

    if (!subject) {
        return sendValidationError(reply, 'Ticket subject is required');
    }
    if (!description) {
        return sendValidationError(reply, 'Ticket description is required');
    }
    if (!ticketPriorities.includes(priority)) {
        return sendValidationError(reply, 'Ticket priority is invalid');
    }
    if (subject.length > 140) {
        return sendValidationError(reply, 'Ticket subject cannot exceed 140 characters');
    }
    if (description.length > 4000) {
        return sendValidationError(reply, 'Ticket description cannot exceed 4000 characters');
    }

    const createdAt = nowIso();
    const ticket: SupportTicket = {
        id: makeId('ticket'),
        subject,
        description,
        priority,
        status: 'open',
        createdBy: user.sub,
        assigneeId: null,
        orderId,
        resolutionNote: null,
        createdAt,
        updatedAt: createdAt,
    };

    supportTickets.set(ticket.id, ticket);
    return reply.code(201).send({ ticket });
};

export const updateSupportTicket = async (
    request: FastifyRequest<{
        Params: { id: string };
        Body: {
            status?: TicketStatus;
            assigneeId?: string | null;
            priority?: TicketPriority;
            resolutionNote?: string | null;
        };
    }>,
    reply: FastifyReply,
) => {
    const user = userFromRequest(request);
    if (!user?.sub) {
        return reply.code(401).send({ error: 'Unauthorized', message: 'Authentication required' });
    }

    const ticket = supportTickets.get(request.params.id);
    if (!ticket) {
        return sendNotFound(reply, 'Support ticket not found');
    }

    const isAdmin = user.role === 'admin';
    const isOwner = ticket.createdBy === user.sub;
    if (!isAdmin && !isOwner) {
        return sendForbidden(reply, 'You cannot update this ticket');
    }

    const nextStatus = request.body?.status;
    const nextPriority = request.body?.priority;
    const nextAssignee = request.body?.assigneeId;
    const nextResolutionNote = request.body?.resolutionNote?.trim();

    if (nextStatus && !ticketStatuses.includes(nextStatus)) {
        return sendValidationError(reply, 'Ticket status is invalid');
    }
    if (nextPriority && !ticketPriorities.includes(nextPriority)) {
        return sendValidationError(reply, 'Ticket priority is invalid');
    }
    if (nextResolutionNote && nextResolutionNote.length > 2000) {
        return sendValidationError(reply, 'Resolution note cannot exceed 2000 characters');
    }

    if (!isAdmin) {
        if (nextStatus && nextStatus !== 'closed') {
            return sendForbidden(reply, 'Only admins can set non-closed statuses');
        }
        if (nextPriority || typeof nextAssignee !== 'undefined') {
            return sendForbidden(reply, 'Only admins can change priority or assignee');
        }
    }

    if (nextStatus) {
        ticket.status = nextStatus;
    }
    if (nextPriority) {
        ticket.priority = nextPriority;
    }
    if (typeof nextAssignee !== 'undefined') {
        ticket.assigneeId = nextAssignee ? nextAssignee.trim() : null;
    }
    if (typeof request.body?.resolutionNote !== 'undefined') {
        ticket.resolutionNote = nextResolutionNote || null;
    }
    ticket.updatedAt = nowIso();
    supportTickets.set(ticket.id, ticket);

    return reply.send({ ticket });
};

export const __resetChatStateForTests = () => {
    chatRooms.clear();
    chatMessages.clear();
    supportTickets.clear();
};
