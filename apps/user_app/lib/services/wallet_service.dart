import 'package:dio/dio.dart';
import 'api_service.dart';

class WalletService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> createTopupPayment(double amount) async {
    final response = await _api.post('/wallet/create-payment', data: {
      'amount': amount,
    });
    return (response.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> verifyTopup({
    required String orderId,
    required String paymentId,
    required String signature,
    required double amount,
  }) async {
    final response = await _api.post('/wallet/verify-topup', data: {
      'razorpay_order_id': orderId,
      'razorpay_payment_id': paymentId,
      'razorpay_signature': signature,
      'amount': amount,
    });
    return (response.data as Map).cast<String, dynamic>();
  }
}
