import { FastifyReply, FastifyRequest } from 'fastify';
import { supabase } from '../services/supabase';
import { buildPaginationMeta, parsePagination } from '../utils/pagination';

type ChatRoomStatus = 'active' | 'closed';
type TicketStatus = 'open' | 'in_progress' | 'resolved' | 'closed';
type TicketPriority = 'low' | 'normal' | 'high' | 'urgent';

type ChatRoomRecord = {
    id: string;
    topic: string | null;
    status: ChatRoomStatus;
    created_by: string | null;
    created_at: string;
    updated_at: string;
};

type ChatMessageRecord = {
    id: string;
    room_id: string;
    sender_id: string | null;
    message: string | null;
    sent_at: string | null;
};

type SupportTicketRecord = {
    id: string;
    subject: string;
    description: string;
    priority: TicketPriority;
    status: TicketStatus;
    user_id: string;
    assignee_id: string | null;
    order_id: string | null;
    resolution_note: string | null;
    created_at: string;
    updated_at: string;
};

type SupportTicketEventRecord = {
    id: string;
    ticket_id: string;
    actor_id: string | null;
    actor_role: string | null;
    event_type: string;
    event_payload: Record<string, unknown> | null;
    created_at: string;
};

const nowIso = () => new Date().toISOString();

const ticketStatuses: TicketStatus[] = ['open', 'in_progress', 'resolved', 'closed'];
const ticketPriorities: TicketPriority[] = ['low', 'normal', 'high', 'urgent'];

const sendValidationError = (reply: FastifyReply, message: string) =>
    reply.code(400).send({ error: 'ValidationError', message });

const sendForbidden = (reply: FastifyReply, message: string) =>
    reply.code(403).send({ error: 'Forbidden', message });

const sendNotFound = (reply: FastifyReply, message: string) =>
    reply.code(404).send({ error: 'NotFound', message });

const userFromRequest = (request: FastifyRequest) => request.user as { sub: string; role: string } | undefined;

const mapChatRoom = (room: ChatRoomRecord, participants: string[]) => ({
    id: room.id,
    topic: room.topic ?? 'Support conversation',
    status: room.status,
    createdBy: room.created_by ?? '',
    participants,
    createdAt: room.created_at,
    updatedAt: room.updated_at,
});

const mapChatMessage = (message: ChatMessageRecord) => ({
    id: message.id,
    roomId: message.room_id,
    senderId: message.sender_id ?? '',
    content: message.message ?? '',
    createdAt: message.sent_at ?? nowIso(),
});

const mapSupportTicket = (ticket: SupportTicketRecord) => ({
    id: ticket.id,
    subject: ticket.subject,
    description: ticket.description,
    priority: ticket.priority,
    status: ticket.status,
    createdBy: ticket.user_id,
    assigneeId: ticket.assignee_id,
    orderId: ticket.order_id,
    resolutionNote: ticket.resolution_note,
    createdAt: ticket.created_at,
    updatedAt: ticket.updated_at,
});

const mapSupportTicketEvent = (event: SupportTicketEventRecord) => ({
    id: event.id,
    ticketId: event.ticket_id,
    actorId: event.actor_id,
    actorRole: event.actor_role,
    eventType: event.event_type,
    payload: event.event_payload || {},
    createdAt: event.created_at,
});

const recordSupportTicketEvent = async (
    ticketId: string,
    actor: { id?: string | null; role?: string | null },
    eventType: string,
    payload: Record<string, unknown>,
) => {
    const { error } = await supabase
        .from('support_ticket_events')
        .insert({
            ticket_id: ticketId,
            actor_id: actor.id || null,
            actor_role: actor.role || null,
            event_type: eventType,
            event_payload: payload,
            created_at: nowIso(),
        });
    if (error) throw error;
};

const getRoomParticipants = async (roomId: string): Promise<string[]> => {
    const { data, error } = await supabase
        .from('chat_room_participants')
        .select('user_id')
        .eq('room_id', roomId);

    if (error) throw error;
    return (data || [])
        .map((entry: any) => entry.user_id)
        .filter((id: unknown): id is string => typeof id === 'string' && id.length > 0);
};

const userCanAccessRoom = async (roomId: string, userId: string, role: string) => {
    if (role === 'admin') return true;
    const participants = await getRoomParticipants(roomId);
    return participants.includes(userId);
};

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
    const { data: room, error: roomError } = await supabase
        .from('chat_rooms')
        .insert({
            topic,
            status: 'active',
            created_by: user.sub,
            created_at: createdAt,
            updated_at: createdAt,
        })
        .select('*')
        .single();

    if (roomError) throw roomError;

    const participantRows = participants.map((participantId) => ({
        room_id: room.id,
        user_id: participantId,
        joined_at: createdAt,
    }));

    const { error: participantsError } = await supabase
        .from('chat_room_participants')
        .upsert(participantRows, { onConflict: 'room_id,user_id' });

    if (participantsError) throw participantsError;

    return reply.code(201).send({ room: mapChatRoom(room as ChatRoomRecord, participants) });
};

export const getChatMessages = async (
    request: FastifyRequest<{ Params: { id: string }; Querystring: { limit?: number } }>,
    reply: FastifyReply,
) => {
    const user = userFromRequest(request);
    if (!user?.sub) {
        return reply.code(401).send({ error: 'Unauthorized', message: 'Authentication required' });
    }

    const { data: room, error: roomError } = await supabase
        .from('chat_rooms')
        .select('*')
        .eq('id', request.params.id)
        .maybeSingle();

    if (roomError) throw roomError;
    if (!room) {
        return sendNotFound(reply, 'Chat room not found');
    }
    const canAccessRoom = await userCanAccessRoom(room.id, user.sub, user.role);
    if (!canAccessRoom) {
        return sendForbidden(reply, 'You are not a participant in this chat room');
    }

    const rawLimit = Number(request.query?.limit ?? 50);
    const limit = Number.isFinite(rawLimit) ? Math.max(1, Math.min(rawLimit, 100)) : 50;
    const { data: messages, error: messagesError } = await supabase
        .from('chat_messages')
        .select('*')
        .eq('room_id', room.id)
        .order('sent_at', { ascending: false })
        .limit(limit);

    if (messagesError) throw messagesError;

    const normalized = (messages || []).reverse().map((message) => mapChatMessage(message as ChatMessageRecord));
    return reply.send({ roomId: room.id, messages: normalized, meta: { count: normalized.length, limit } });
};

export const sendChatMessage = async (
    request: FastifyRequest<{ Params: { id: string }; Body: { content?: string } }>,
    reply: FastifyReply,
) => {
    const user = userFromRequest(request);
    if (!user?.sub) {
        return reply.code(401).send({ error: 'Unauthorized', message: 'Authentication required' });
    }

    const { data: room, error: roomError } = await supabase
        .from('chat_rooms')
        .select('*')
        .eq('id', request.params.id)
        .maybeSingle();

    if (roomError) throw roomError;
    if (!room) {
        return sendNotFound(reply, 'Chat room not found');
    }
    if (room.status !== 'active') {
        return sendValidationError(reply, 'Chat room is closed');
    }
    const canAccessRoom = await userCanAccessRoom(room.id, user.sub, user.role);
    if (!canAccessRoom) {
        return sendForbidden(reply, 'You are not a participant in this chat room');
    }

    const content = request.body?.content?.trim();
    if (!content) {
        return sendValidationError(reply, 'Message content is required');
    }
    if (content.length > 2000) {
        return sendValidationError(reply, 'Message content cannot exceed 2000 characters');
    }

    const senderType = user.role === 'vendor' ? 'vendor' : user.role === 'admin' ? 'admin' : 'user';
    const { data: message, error: messageError } = await supabase
        .from('chat_messages')
        .insert({
            room_id: room.id,
            sender_type: senderType,
            sender_id: user.sub,
            message: content,
            sent_at: nowIso(),
            is_read: false,
        })
        .select('*')
        .single();

    if (messageError) throw messageError;

    const { error: roomUpdateError } = await supabase
        .from('chat_rooms')
        .update({ updated_at: nowIso() })
        .eq('id', room.id);

    if (roomUpdateError) throw roomUpdateError;

    return reply.code(201).send({ message: mapChatMessage(message as ChatMessageRecord) });
};

export const listSupportTickets = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = userFromRequest(request);
    if (!user?.sub) {
        return reply.code(401).send({ error: 'Unauthorized', message: 'Authentication required' });
    }

    const query = supabase.from('support_tickets').select('*').order('updated_at', { ascending: false });
    if (user.role !== 'admin') {
        query.eq('user_id', user.sub);
    }

    const { data, error } = await query;
    if (error) throw error;

    const tickets = (data || []).map((ticket) => mapSupportTicket(ticket as SupportTicketRecord));
    return reply.send({ tickets });
};

export const listMySupportTickets = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = userFromRequest(request);
    if (!user?.sub) {
        return reply.code(401).send({ error: 'Unauthorized', message: 'Authentication required' });
    }

    const { data, error } = await supabase
        .from('support_tickets')
        .select('*')
        .eq('user_id', user.sub)
        .order('updated_at', { ascending: false });

    if (error) throw error;
    const tickets = (data || []).map((ticket) => mapSupportTicket(ticket as SupportTicketRecord));
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
    const { data: ticket, error } = await supabase
        .from('support_tickets')
        .insert({
            subject,
            description,
            priority,
            status: 'open',
            user_id: user.sub,
            assignee_id: null,
            order_id: orderId,
            resolution_note: null,
            created_at: createdAt,
            updated_at: createdAt,
        })
        .select('*')
        .single();

    if (error) throw error;
    await recordSupportTicketEvent(
        ticket.id,
        { id: user.sub, role: user.role },
        'ticket.created',
        { status: 'open', priority, orderId },
    );
    return reply.code(201).send({ ticket: mapSupportTicket(ticket as SupportTicketRecord) });
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

    const { data: ticket, error: ticketError } = await supabase
        .from('support_tickets')
        .select('*')
        .eq('id', request.params.id)
        .maybeSingle();

    if (ticketError) throw ticketError;
    if (!ticket) {
        return sendNotFound(reply, 'Support ticket not found');
    }

    const isAdmin = user.role === 'admin';
    const isOwner = ticket.user_id === user.sub;
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

    const updates: Record<string, unknown> = { updated_at: nowIso() };
    if (nextStatus) updates.status = nextStatus;
    if (nextPriority) updates.priority = nextPriority;
    if (typeof nextAssignee !== 'undefined') updates.assignee_id = nextAssignee ? nextAssignee.trim() : null;
    if (typeof request.body?.resolutionNote !== 'undefined') updates.resolution_note = nextResolutionNote || null;

    const { data: updatedTicket, error: updateError } = await supabase
        .from('support_tickets')
        .update(updates)
        .eq('id', ticket.id)
        .select('*')
        .single();

    if (updateError) throw updateError;
    await recordSupportTicketEvent(
        ticket.id,
        { id: user.sub, role: user.role },
        'ticket.updated',
        {
            previous: {
                status: ticket.status,
                priority: ticket.priority,
                assignee_id: ticket.assignee_id,
            },
            next: {
                status: (updatedTicket as any).status,
                priority: (updatedTicket as any).priority,
                assignee_id: (updatedTicket as any).assignee_id,
            },
        },
    );
    return reply.send({ ticket: mapSupportTicket(updatedTicket as SupportTicketRecord) });
};

export const listAdminSupportTickets = async (
    request: FastifyRequest<{
        Querystring: {
            page?: string | number;
            limit?: string | number;
            status?: TicketStatus;
            priority?: TicketPriority;
            assigneeId?: string;
            updatedFrom?: string;
            updatedTo?: string;
        };
    }>,
    reply: FastifyReply,
) => {
    const user = userFromRequest(request);
    if (!user?.sub || user.role !== 'admin') {
        return sendForbidden(reply, 'Admin access required');
    }

    const { page, limit, from, to } = parsePagination(request.query || {}, { defaultLimit: 20, maxLimit: 100 });
    let countQuery = supabase.from('support_tickets').select('*', { count: 'exact', head: true });
    let dataQuery = supabase.from('support_tickets').select('*').order('updated_at', { ascending: false }).range(from, to);

    if (request.query?.status) {
        countQuery = countQuery.eq('status', request.query.status);
        dataQuery = dataQuery.eq('status', request.query.status);
    }
    if (request.query?.priority) {
        countQuery = countQuery.eq('priority', request.query.priority);
        dataQuery = dataQuery.eq('priority', request.query.priority);
    }
    if (typeof request.query?.assigneeId !== 'undefined') {
        const assigneeId = request.query.assigneeId?.trim();
        if (assigneeId) {
            countQuery = countQuery.eq('assignee_id', assigneeId);
            dataQuery = dataQuery.eq('assignee_id', assigneeId);
        } else {
            countQuery = countQuery.is('assignee_id', null);
            dataQuery = dataQuery.is('assignee_id', null);
        }
    }
    if (request.query?.updatedFrom) {
        countQuery = countQuery.gte('updated_at', request.query.updatedFrom);
        dataQuery = dataQuery.gte('updated_at', request.query.updatedFrom);
    }
    if (request.query?.updatedTo) {
        countQuery = countQuery.lte('updated_at', request.query.updatedTo);
        dataQuery = dataQuery.lte('updated_at', request.query.updatedTo);
    }

    const [{ count, error: countError }, { data, error: dataError }] = await Promise.all([countQuery, dataQuery]);
    if (countError) throw countError;
    if (dataError) throw dataError;

    const total = count || 0;
    return reply.send({
        tickets: (data || []).map((ticket) => mapSupportTicket(ticket as SupportTicketRecord)),
        page,
        limit,
        total,
        meta: buildPaginationMeta(page, limit, total),
    });
};

export const getAdminSupportSummary = async (request: FastifyRequest, reply: FastifyReply) => {
    const user = userFromRequest(request);
    if (!user?.sub || user.role !== 'admin') {
        return sendForbidden(reply, 'Admin access required');
    }

    const summary = {
        total: 0,
        status: {
            open: 0,
            in_progress: 0,
            resolved: 0,
            closed: 0,
        } as Record<TicketStatus, number>,
        priority: {
            low: 0,
            normal: 0,
            high: 0,
            urgent: 0,
        } as Record<TicketPriority, number>,
    };

    const totalQuery = supabase.from('support_tickets').select('id', { count: 'exact', head: true });
    const statusQueries = ticketStatuses.map((status) =>
        supabase.from('support_tickets').select('id', { count: 'exact', head: true }).eq('status', status),
    );
    const priorityQueries = ticketPriorities.map((priority) =>
        supabase.from('support_tickets').select('id', { count: 'exact', head: true }).eq('priority', priority),
    );

    const [totalResult, ...bucketResults] = await Promise.all([totalQuery, ...statusQueries, ...priorityQueries]);
    if (totalResult.error) throw totalResult.error;
    summary.total = totalResult.count || 0;

    ticketStatuses.forEach((status, idx) => {
        const result = bucketResults[idx];
        if (result.error) throw result.error;
        summary.status[status] = result.count || 0;
    });

    ticketPriorities.forEach((priority, idx) => {
        const result = bucketResults[ticketStatuses.length + idx];
        if (result.error) throw result.error;
        summary.priority[priority] = result.count || 0;
    });

    // Keep aggregate in sync even if DB count semantics change.
    const statusTotal = ticketStatuses.reduce((acc, status) => acc + (summary.status[status] || 0), 0);
    if (statusTotal > summary.total) {
        summary.total = statusTotal;
    }

    return reply.send({ summary });
};

export const updateAdminSupportTicket = async (
    request: FastifyRequest<{
        Params: { id: string };
        Body: { status?: TicketStatus; priority?: TicketPriority; assigneeId?: string | null; resolutionNote?: string | null };
    }>,
    reply: FastifyReply,
) => {
    const user = userFromRequest(request);
    if (!user?.sub || user.role !== 'admin') {
        return sendForbidden(reply, 'Admin access required');
    }

    const { data: ticket, error: ticketError } = await supabase
        .from('support_tickets')
        .select('*')
        .eq('id', request.params.id)
        .maybeSingle();

    if (ticketError) throw ticketError;
    if (!ticket) return sendNotFound(reply, 'Support ticket not found');

    const updates: Record<string, unknown> = { updated_at: nowIso() };
    if (request.body?.status) {
        if (!ticketStatuses.includes(request.body.status)) return sendValidationError(reply, 'Ticket status is invalid');
        updates.status = request.body.status;
    }
    if (request.body?.priority) {
        if (!ticketPriorities.includes(request.body.priority)) return sendValidationError(reply, 'Ticket priority is invalid');
        updates.priority = request.body.priority;
    }
    if (typeof request.body?.assigneeId !== 'undefined') {
        updates.assignee_id = request.body.assigneeId ? request.body.assigneeId.trim() : null;
    }
    if (typeof request.body?.resolutionNote !== 'undefined') {
        const resolutionNote = request.body.resolutionNote?.trim();
        if (resolutionNote && resolutionNote.length > 2000) return sendValidationError(reply, 'Resolution note cannot exceed 2000 characters');
        updates.resolution_note = resolutionNote || null;
    }

    const { data: updatedTicket, error: updateError } = await supabase
        .from('support_tickets')
        .update(updates)
        .eq('id', request.params.id)
        .select('*')
        .single();

    if (updateError) throw updateError;
    await recordSupportTicketEvent(
        ticket.id,
        { id: user.sub, role: user.role },
        'ticket.admin_updated',
        {
            previous: {
                status: ticket.status,
                priority: ticket.priority,
                assignee_id: ticket.assignee_id,
            },
            next: {
                status: (updatedTicket as any).status,
                priority: (updatedTicket as any).priority,
                assignee_id: (updatedTicket as any).assignee_id,
            },
        },
    );
    return reply.send({ ticket: mapSupportTicket(updatedTicket as SupportTicketRecord) });
};

export const getSupportTicketTimeline = async (
    request: FastifyRequest<{ Params: { id: string }; Querystring: { limit?: string | number } }>,
    reply: FastifyReply,
) => {
    const user = userFromRequest(request);
    if (!user?.sub) {
        return reply.code(401).send({ error: 'Unauthorized', message: 'Authentication required' });
    }

    const { data: ticket, error: ticketError } = await supabase
        .from('support_tickets')
        .select('*')
        .eq('id', request.params.id)
        .maybeSingle();
    if (ticketError) throw ticketError;
    if (!ticket) return sendNotFound(reply, 'Support ticket not found');

    const isAdmin = user.role === 'admin';
    if (!isAdmin && ticket.user_id !== user.sub) {
        return sendForbidden(reply, 'You cannot view this ticket timeline');
    }

    const rawLimit = Number(request.query?.limit ?? 100);
    const limit = Number.isFinite(rawLimit) ? Math.max(1, Math.min(rawLimit, 300)) : 100;
    const { data: events, error } = await supabase
        .from('support_ticket_events')
        .select('*')
        .eq('ticket_id', ticket.id)
        .order('created_at', { ascending: false })
        .limit(limit);
    if (error) throw error;

    const timeline = (events || [])
        .map((event) => mapSupportTicketEvent(event as SupportTicketEventRecord))
        .reverse();
    return reply.send({ ticketId: ticket.id, events: timeline });
};

export const __resetChatStateForTests = () => undefined;
