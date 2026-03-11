import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vendor_app/core/api_service.dart';

final menuProvider = StateNotifierProvider<MenuNotifier, AsyncValue<List<dynamic>>>((ref) {
  return MenuNotifier(ref.watch(apiServiceProvider));
});

class MenuNotifier extends StateNotifier<AsyncValue<List<dynamic>>> {
  final ApiService _api;

  MenuNotifier(this._api) : super(const AsyncValue.loading());

  Future<void> fetchMenus(String vendorId) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.get('/menus/vendor/$vendorId');
      if (response.statusCode == 200) {
        state = AsyncValue.data(response.data);
      } else {
        state = AsyncValue.error('Failed to fetch menus', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
    }
  }

  Future<void> createMenu(Map<String, dynamic> data) async {
    try {
      await _api.post('/menus', data: data);
      // Re-fetch should be done with vendorId
    } catch (e) {
      // Handle error
    }
  }
}
