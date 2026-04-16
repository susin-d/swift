import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vendor_model.dart';
import '../models/menu_model.dart';
import '../models/recommended_item.dart';
import '../services/vendor_service.dart';

final vendorServiceProvider = Provider((ref) => VendorService());

final vendorsProvider = FutureProvider<List<VendorModel>>((ref) async {
  return ref.watch(vendorServiceProvider).getAllVendors();
});

final vendorMenuProvider = FutureProvider.family<List<MenuItemModel>, String>((ref, vendorId) async {
  return ref.watch(vendorServiceProvider).getVendorMenu(vendorId);
});

final recommendedItemsProvider = FutureProvider<List<RecommendedItem>>((ref) async {
  return ref.watch(vendorServiceProvider).getRecommendedItems(limit: 12);
});

final allFoodItemsProvider = FutureProvider<List<RecommendedItem>>((ref) async {
  return ref.watch(vendorServiceProvider).getAllFoodItems();
});
