import '../../core/api_service.dart';

class HandoffService {
  final ApiService _api = ApiService();

  Future<void> updateHandoff(String orderId, String status, {String? proofUrl}) async {
    await _api.patch('/orders/$orderId/handoff', data: {
      'status': status,
      if (proofUrl != null) 'proof_url': proofUrl,
    });
  }
}
