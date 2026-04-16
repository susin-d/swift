import 'api_service.dart';

class PaymentService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> createRazorpayOrder({
    required String backendOrderId,
    String currency = 'INR',
  }) async {
    final response = await _api.post('/payments/create-order', data: {
      'order_id': backendOrderId,
      'currency': currency,
    });
    return (response.data as Map).cast<String, dynamic>();
  }

  Future<void> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    await _api.post('/payments/verify', data: {
      'razorpay_order_id': orderId,
      'razorpay_payment_id': paymentId,
      'razorpay_signature': signature,
    });
  }
}
