import 'api_service.dart';
import '../models/menu_model.dart';
import '../models/vendor_model.dart';

class SearchService {
  final ApiService _api = ApiService();

  Future<List<Map<String, dynamic>>> searchItems(String query) async {
    final response = await _api.get('/public/search', queryParameters: {'q': query});
    return List<Map<String, dynamic>>.from(response.data);
  }
}
