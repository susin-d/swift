import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vendor_app/core/api_service.dart';
import 'menu_models.dart';

final menuProvider = StateNotifierProvider<MenuNotifier, AsyncValue<MenuSnapshot>>((ref) {
  return MenuNotifier(ref.watch(apiServiceProvider));
});

class MenuNotifier extends StateNotifier<AsyncValue<MenuSnapshot>> {
  final ApiService _api;

  MenuNotifier(this._api) : super(const AsyncValue.loading());

  Future<void> fetchMenus() async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.get('/vendor-ops/menu');
      if (response.statusCode == 200) {
        final snapshot = MenuSnapshot.fromVendorOps((response.data as Map).cast<String, dynamic>());
        state = AsyncValue.data(snapshot);
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
      await fetchMenus();
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<void> updateMenu(String id, Map<String, dynamic> data) async {
    try {
      await _api.patch('/menus/$id', data: data);
      await fetchMenus();
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<void> deleteMenu(String id) async {
    try {
      await _api.delete('/menus/$id');
      await fetchMenus();
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<void> createMenuItem(Map<String, dynamic> data) async {
    try {
      await _api.post('/menus/items', data: data);
      await fetchMenus();
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<void> updateMenuItem(String id, Map<String, dynamic> data) async {
    try {
      await _api.patch('/menus/items/$id', data: data);
      await fetchMenus();
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<void> deleteMenuItem(String id) async {
    try {
      await _api.delete('/menus/items/$id');
      await fetchMenus();
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }
}
