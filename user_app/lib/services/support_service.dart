import 'api_service.dart';

abstract class SupportTicketGateway {
  Future<String?> createTicket({
    required String subject,
    required String description,
    required String priority,
    String? orderId,
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
}
