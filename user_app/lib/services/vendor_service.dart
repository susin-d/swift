import '../models/vendor_model.dart';
import '../models/menu_model.dart';
import '../models/recommended_item.dart';
import 'api_exception.dart';
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

  Future<List<RecommendedItem>> getRecommendedItems({int limit = 12}) async {
    try {
      final response = await _api.get('/public/recommendations', queryParameters: {'limit': limit});
      final List data = response.data ?? [];
      return data
          .whereType<Map>()
          .map((json) => RecommendedItem.fromJson(json.cast<String, dynamic>()))
          .toList();
    } on ApiException catch (e) {
      // Backward compatibility for deployments that do not expose /public/recommendations yet.
      if (e.statusCode != 404 && e.statusCode != 500 && e.statusCode != 503) {
        rethrow;
      }

      final vendors = await getAllVendors();
      final fallbackItems = <RecommendedItem>[];

      for (final vendor in vendors) {
        if (fallbackItems.length >= limit) break;

        try {
          final menuItems = await getVendorMenu(vendor.id);
          final firstAvailable = menuItems.firstWhere(
            (item) => item.isAvailable,
            orElse: () => menuItems.isNotEmpty
                ? menuItems.first
                : MenuItemModel(
                    id: '',
                    menuId: '',
                    vendorId: vendor.id,
                    name: '',
                    price: 0,
                  ),
          );

          if (firstAvailable.id.isEmpty || firstAvailable.name.trim().isEmpty) {
            continue;
          }

          fallbackItems.add(
            RecommendedItem(
              id: firstAvailable.id,
              name: firstAvailable.name,
              description: firstAvailable.description,
              price: firstAvailable.price,
              imageUrl: firstAvailable.imageUrl,
              category: firstAvailable.category,
              score: vendor.rating,
              vendor: RecommendedVendor(
                id: vendor.id,
                name: vendor.name,
                description: vendor.description,
                imageUrl: vendor.imageUrl,
                isOpen: vendor.isOpen,
              ),
            ),
          );
        } catch (_) {
          // Skip vendor if its menu call fails; continue building a partial feed.
        }
      }

      return fallbackItems.take(limit).toList();
    }
  }
}
