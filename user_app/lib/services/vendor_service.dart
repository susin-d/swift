import '../models/vendor_model.dart';
import '../models/menu_model.dart';
import 'api_service.dart';

class VendorService {
  final ApiService _api = ApiService();

  Future<List<VendorModel>> getAllVendors() async {
    final response = await _api.get('/public/vendors');
    final List data = response.data ?? [];
    return data.map((json) => VendorModel.fromJson(json)).toList();
  }

  Future<List<MenuItemModel>> getVendorMenu(String vendorId) async {
    final response = await _api.get('/menus/vendor/$vendorId');
    final List menus = response.data ?? [];

    // Backend returns menu categories with nested menu_items.
    final List<Map<String, dynamic>> flattenedItems = menus
        .whereType<Map<String, dynamic>>()
        .expand((menu) {
          final category = menu['category_name'];
          final vendorId = menu['vendor_id'];
          final items = (menu['menu_items'] as List?) ?? const [];
          return items.whereType<Map<String, dynamic>>().map((item) {
            return {
              ...item,
              'category': category,
              'vendor_id': vendorId,
            };
          });
        })
        .toList();

    return flattenedItems.map((json) => MenuItemModel.fromJson(json)).toList();
  }
}
