import 'api_exception.dart';
import 'api_service.dart';

class CartService {
  final ApiService _api = ApiService();

  Future<List<Map<String, dynamic>>?> getCartItems() async {
    try {
      final response = await _api.get('/cart');
      final data = response.data as Map<String, dynamic>? ?? {};
      final items = data['items'];
      if (items is! List) return const [];
      return items
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403 || e.statusCode == 503) {
        return null;
      }
      rethrow;
    }
  }

  Future<void> setCartItems(List<Map<String, dynamic>> items) async {
    try {
      await _api.patch('/cart', data: {'items': items});
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403 || e.statusCode == 503) {
        return;
      }
      rethrow;
    }
  }
}
