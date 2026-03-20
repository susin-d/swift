import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/menu_model.dart';

class CartItem {
  final MenuItemModel item;
  int quantity;

  CartItem({required this.item, this.quantity = 1});
}

class CartNotifier extends StateNotifier<Map<String, CartItem>> {
  static const String _storageKey = 'user_app_cart_v1';

  CartNotifier() : super({}) {
    _loadCart();
  }

  Future<void> _loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_storageKey);
      if (encoded == null || encoded.isEmpty || state.isNotEmpty) return;

      final decoded = jsonDecode(encoded);
      if (decoded is! List) return;

      final restored = <String, CartItem>{};
      for (final entry in decoded) {
        if (entry is! Map<String, dynamic>) continue;
        final itemJson = entry['item'];
        final quantityValue = entry['quantity'];
        if (itemJson is! Map<String, dynamic> || quantityValue is! num) continue;

        final item = MenuItemModel.fromJson(itemJson);
        final quantity = quantityValue.toInt();
        if (quantity <= 0) continue;

        restored[item.id] = CartItem(item: item, quantity: quantity);
      }

      state = restored;
    } catch (_) {
      // Ignore malformed cache and keep an empty in-memory cart.
    }
  }

  Future<void> _persistCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = state.values
          .map(
            (cartItem) => {
              'item': cartItem.item.toJson(),
              'quantity': cartItem.quantity,
            },
          )
          .toList();
      await prefs.setString(_storageKey, jsonEncode(payload));
    } catch (_) {
      // Keep cart usable even if persistence fails.
    }
  }

  void addItem(MenuItemModel item) {
    if (state.containsKey(item.id)) {
      state[item.id]!.quantity++;
      state = Map<String, CartItem>.from(state);
    } else {
      final newState = Map<String, CartItem>.from(state);
      newState[item.id] = CartItem(item: item);
      state = newState;
    }
    _persistCart();
  }

  void removeItem(MenuItemModel item) {
    if (state.containsKey(item.id)) {
      if (state[item.id]!.quantity > 1) {
        state[item.id]!.quantity--;
        state = Map<String, CartItem>.from(state);
      } else {
        final newState = Map<String, CartItem>.from(state);
        newState.remove(item.id);
        state = newState;
      }
      _persistCart();
    }
  }

  void clearCart() {
    state = {};
    _persistCart();
  }

  double get totalAmount {
    double total = 0.0;
    state.forEach((key, cartItem) {
      total += cartItem.item.price * cartItem.quantity;
    });
    return total;
  }

  int get itemCount => state.values.fold<int>(0, (sum, item) => sum + item.quantity);
}

final cartProvider = StateNotifierProvider<CartNotifier, Map<String, CartItem>>((ref) {
  return CartNotifier();
});
