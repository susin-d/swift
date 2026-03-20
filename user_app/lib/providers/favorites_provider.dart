import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _favoritesKey = 'favorite_vendors';

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  return FavoritesNotifier();
});

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier() : super(<String>{}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_favoritesKey) ?? <String>[];
    state = stored.toSet();
  }

  Future<void> toggle(String vendorId) async {
    if (vendorId.isEmpty) return;
    final next = Set<String>.from(state);
    if (next.contains(vendorId)) {
      next.remove(vendorId);
    } else {
      next.add(vendorId);
    }
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, next.toList());
  }

  bool isFavorite(String vendorId) => state.contains(vendorId);
}
