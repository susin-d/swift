import 'api_service.dart';

class ReviewService {
  final ApiService _api = ApiService();

  Future<void> submitReview({
    required String orderId,
    required int rating,
    String? comment,
  }) async {
    await _api.post('/reviews', data: {
      'order_id': orderId,
      'rating': rating,
      'comment': comment,
    });
  }

  Future<List<dynamic>> getVendorReviews(String vendorId) async {
    final response = await _api.get('/reviews/vendor/$vendorId');
    return response.data;
  }
}
