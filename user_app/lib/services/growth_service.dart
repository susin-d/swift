import 'api_service.dart';

class GrowthService {
  GrowthService({ApiService? apiService}) : _api = apiService ?? ApiService();

  final ApiService _api;

  Future<Map<String, dynamic>> getSpendingSummary() async {
    final response = await _api.get('/analytics/spending');
    return (response.data as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getVendorSpending() async {
    final response = await _api.get('/analytics/vendors');
    return (response.data as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
  }

  Future<Map<String, dynamic>> generateReferralCode() async {
    final response = await _api.post('/referrals/generate');
    return (response.data as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
  }

  Future<Map<String, dynamic>> redeemReferralCode(String code) async {
    final response = await _api.post('/referrals/redeem', data: {'code': code});
    return (response.data as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getLoyaltyTier() async {
    final response = await _api.get('/loyalty/tier');
    return (response.data as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
  }

  Future<Map<String, dynamic>> addLoyaltyPoints(int points) async {
    final response =
        await _api.post('/loyalty/points', data: {'points': points});
    return (response.data as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
  }

  Future<List<dynamic>> getSubscriptions() async {
    final response = await _api.get('/subscriptions');
    final payload = (response.data as Map?)?.cast<String, dynamic>();
    return payload?['subscriptions'] as List<dynamic>? ?? const [];
  }

  Future<Map<String, dynamic>> createSubscription(String plan) async {
    final response =
        await _api.post('/subscriptions/create', data: {'plan': plan});
    return (response.data as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
  }

  Future<Map<String, dynamic>> renewSubscription(String subscriptionId) async {
    final response = await _api.patch('/subscriptions/$subscriptionId/renew');
    return (response.data as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
  }

  Future<Map<String, dynamic>> cancelSubscription(String subscriptionId) async {
    final response = await _api.patch('/subscriptions/$subscriptionId/cancel');
    return (response.data as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getEntitlements() async {
    final response = await _api.get('/subscriptions/entitlements');
    return (response.data as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
  }

  Future<List<dynamic>> getRefunds() async {
    final response = await _api.get('/refunds/me');
    final payload = (response.data as Map?)?.cast<String, dynamic>();
    return payload?['refunds'] as List<dynamic>? ?? const [];
  }

  Future<Map<String, dynamic>> requestRefund({
    required String orderId,
    required String reason,
    double? amount,
  }) async {
    final response = await _api.post(
      '/orders/$orderId/refund',
      data: {'reason': reason, if (amount != null) 'amount': amount},
    );
    return (response.data as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
  }

  Future<Map<String, dynamic>> createGroupOrder({
    required String orderId,
    List<String> participantIds = const [],
  }) async {
    final response = await _api.post(
      '/orders/group',
      data: {'orderId': orderId, 'participantIds': participantIds},
    );
    return (response.data as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getGroupOrder(String orderId) async {
    final response = await _api.get('/orders/$orderId/group');
    return (response.data as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
  }

  Future<Map<String, dynamic>> joinGroupOrder(String orderId) async {
    final response = await _api.post('/orders/$orderId/group/join');
    return (response.data as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
  }

  Future<Map<String, dynamic>> leaveGroupOrder(String orderId) async {
    final response = await _api.post('/orders/$orderId/group/leave');
    return (response.data as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
  }

  Future<Map<String, dynamic>> requestAccountDeletion() async {
    final response = await _api.delete('/users/me');
    return (response.data as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getDeletionStatus() async {
    final response = await _api.get('/users/me/deletion');
    return (response.data as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
  }

  Future<Map<String, dynamic>> cancelDeletion() async {
    final response = await _api.patch('/users/me/deletion/cancel');
    return (response.data as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
  }
}
