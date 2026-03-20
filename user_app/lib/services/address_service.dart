import 'api_service.dart';
import 'api_exception.dart';

class AddressService {
  final ApiService _api = ApiService();

  Future<List<dynamic>> getAddresses() async {
    try {
      final response = await _api.get('/addresses');
      return response.data as List<dynamic>? ?? <dynamic>[];
    } on ApiException catch (e) {
      // Keep checkout usable when address service is temporarily unavailable.
      if (e.statusCode >= 500) {
        return <dynamic>[];
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addAddress({
    required String label,
    required String addressLine,
    bool isDefault = false,
  }) async {
    final response = await _api.post('/addresses', data: {
      'label': label,
      'address_line': addressLine,
      'is_default': isDefault,
    });
    return response.data;
  }

  Future<void> deleteAddress(String id) async {
    await _api.delete('/addresses/$id');
  }

  Future<void> setDefault(String id) async {
    await _api.patch('/addresses/$id/default');
  }
}
