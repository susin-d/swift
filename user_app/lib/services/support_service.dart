import 'api_service.dart';

class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.subject,
    required this.description,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.orderId,
    this.assigneeId,
    this.resolutionNote,
  });

  final String id;
  final String subject;
  final String description;
  final String priority;
  final String status;
  final String createdAt;
  final String updatedAt;
  final String? orderId;
  final String? assigneeId;
  final String? resolutionNote;

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'normal',
      status: json['status']?.toString() ?? 'open',
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
      orderId: json['orderId']?.toString(),
      assigneeId: json['assigneeId']?.toString(),
      resolutionNote: json['resolutionNote']?.toString(),
    );
  }
}

abstract class SupportTicketGateway {
  Future<String?> createTicket({
    required String subject,
    required String description,
    required String priority,
    String? orderId,
  });
  Future<List<SupportTicket>> getMyTickets();
  Future<SupportTicket?> updateTicketStatus({
    required String ticketId,
    required String status,
    String? resolutionNote,
  });
}

class SupportService implements SupportTicketGateway {
  SupportService({ApiService? apiService}) : _api = apiService ?? ApiService();

  final ApiService _api;

  @override
  Future<String?> createTicket({
    required String subject,
    required String description,
    required String priority,
    String? orderId,
  }) async {
    final response = await _api.post(
      '/support/tickets',
      data: <String, dynamic>{
        'subject': subject,
        'description': description,
        'priority': priority,
        if (orderId != null && orderId.trim().isNotEmpty)
          'orderId': orderId.trim(),
      },
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final ticket = data['ticket'];
      if (ticket is Map<String, dynamic>) {
        final id = ticket['id'];
        if (id is String && id.isNotEmpty) {
          return id;
        }
      }
    }
    return null;
  }

  @override
  Future<List<SupportTicket>> getMyTickets() async {
    final response = await _api.get('/support/tickets/me');
    final data = response.data;
    if (data is! Map<String, dynamic>) return const <SupportTicket>[];
    final rawTickets = data['tickets'];
    if (rawTickets is! List) return const <SupportTicket>[];
    return rawTickets
        .whereType<Map>()
        .map(
          (item) => SupportTicket.fromJson(
            item.cast<String, dynamic>(),
          ),
        )
        .toList();
  }

  @override
  Future<SupportTicket?> updateTicketStatus({
    required String ticketId,
    required String status,
    String? resolutionNote,
  }) async {
    final response = await _api.patch(
      '/support/tickets/$ticketId',
      data: <String, dynamic>{
        'status': status,
        if (resolutionNote != null && resolutionNote.trim().isNotEmpty)
          'resolutionNote': resolutionNote.trim(),
      },
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final ticket = data['ticket'];
      if (ticket is Map<String, dynamic>) {
        return SupportTicket.fromJson(ticket);
      }
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getTicketTimeline(String ticketId) async {
    final response = await _api.get('/support/tickets/$ticketId/timeline');
    final data = response.data;
    if (data is! Map<String, dynamic>) return const <Map<String, dynamic>>[];
    final rawEvents = data['events'];
    if (rawEvents is! List) return const <Map<String, dynamic>>[];
    return rawEvents
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }
}
