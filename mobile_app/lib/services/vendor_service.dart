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
    final List data = response.data ?? [];
    return data.map((json) => MenuItemModel.fromJson(json)).toList();
  }
}
