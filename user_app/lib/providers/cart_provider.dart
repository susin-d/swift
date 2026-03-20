import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/menu_model.dart';
import '../services/cart_service.dart';

class CartItem {
  final MenuItemModel item;
  int quantity;

  CartItem({required this.item, this.quantity = 1});
}

class CartNotifier extends StateNotifier<Map<String, CartItem>> {
  static const String _storageKey = 'user_app_cart_v1';
  final CartService _cartService = CartService();

  bool _syncInFlight = false;
  bool _syncQueued = false;

  CartNotifier() : super({}) {
    unawaited(_loadCart());
  }

  Future<void> _loadCart() async {
    await _loadLocalCart();
    await _hydrateFromBackend();
  }

  Future<void> _loadLocalCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_storageKey);
      if (encoded == null || encoded.isEmpty) return;

      final decoded = jsonDecode(encoded);
      if (decoded is! List) return;

      final restored = <String, CartItem>{};
      for (final entry in decoded) {
        if (entry is! Map) continue;

        final row = Map<String, dynamic>.from(entry);
        final itemJsonRaw = row['item'];
        final quantityValue = row['quantity'];
        if (itemJsonRaw is! Map || quantityValue is! num) continue;

        final itemJson = Map<String, dynamic>.from(itemJsonRaw);
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

  Future<void> _hydrateFromBackend() async {
    try {
      final remoteRows = await _cartService.getCartItems();
      if (remoteRows == null) return;

      final remoteState = _deserialize(remoteRows);
      if (remoteState.isNotEmpty || state.isEmpty) {
        state = remoteState;
        await _persistLocalOnly();
        return;
      }

      if (state.isNotEmpty) {
        await _cartService.setCartItems(_serializeState(state));
      }
    } catch (_) {
      // Keep local cart behavior when backend sync is unavailable.
    }
  }

  Map<String, CartItem> _deserialize(List<Map<String, dynamic>> rows) {
    final restored = <String, CartItem>{};

    for (final row in rows) {
      final itemRaw = row['item'];
      final quantityRaw = row['quantity'];
      if (itemRaw is! Map || quantityRaw is! num) continue;

      final item = MenuItemModel.fromJson(Map<String, dynamic>.from(itemRaw));
      final quantity = quantityRaw.toInt();
      if (quantity <= 0) continue;

      restored[item.id] = CartItem(item: item, quantity: quantity);
    }

    return restored;
  }

  List<Map<String, dynamic>> _serializeState(Map<String, CartItem> source) {
    return source.values
        .map(
          (cartItem) => {
            'item': cartItem.item.toJson(),
            'quantity': cartItem.quantity,
          },
        )
        .toList();
  }

  Future<void> _persistLocalOnly() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = _serializeState(state);
      await prefs.setString(_storageKey, jsonEncode(payload));
    } catch (_) {
      // Keep cart usable even if persistence fails.
    }
  }

  Future<void> _persistCart({required bool syncBackend}) async {
    await _persistLocalOnly();
    if (syncBackend) {
      unawaited(_syncToBackend());
    }
  }

  Future<void> _syncToBackend() async {
    if (_syncInFlight) {
      _syncQueued = true;
      return;
    }

    _syncInFlight = true;
    try {
      do {
        _syncQueued = false;
        final snapshot = _serializeState(state);
        await _cartService.setCartItems(snapshot);
      } while (_syncQueued);
    } catch (_) {
      // Fall back to local-only persistence when backend sync fails.
    } finally {
      _syncInFlight = false;
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
    unawaited(_persistCart(syncBackend: true));
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
      unawaited(_persistCart(syncBackend: true));
    }
  }

  void clearCart() {
    state = {};
    unawaited(_persistCart(syncBackend: true));
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
