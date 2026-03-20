import '../models/class_session.dart';
import 'api_service.dart';

class ClassSessionService {
  final ApiService _api = ApiService();

  Future<List<ClassSession>> getSessions() async {
    final response = await _api.get('/class-sessions');
    final data = response.data as List? ?? [];
    return data.map((json) => ClassSession.fromJson(json)).toList();
  }

  Future<ClassSession> createSession({
    required String buildingId,
    required String room,
    DateTime? startsAt,
    DateTime? endsAt,
    String? courseLabel,
    String? notes,
  }) async {
    final response = await _api.post('/class-sessions', data: {
      'building_id': buildingId,
      'room': room,
      if (startsAt != null) 'starts_at': startsAt.toIso8601String(),
      if (endsAt != null) 'ends_at': endsAt.toIso8601String(),
      if (courseLabel != null) 'course_label': courseLabel,
      if (notes != null) 'notes': notes,
    });
    return ClassSession.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteSession(String id) async {
    await _api.delete('/class-sessions/$id');
  }
}
