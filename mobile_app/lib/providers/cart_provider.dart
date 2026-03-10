import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/menu_model.dart';

class CartItem {
  final MenuItemModel item;
  int quantity;

  CartItem({required this.item, this.quantity = 1});
}

class CartNotifier extends StateNotifier<Map<String, CartItem>> {
  CartNotifier() : super({});

  void addItem(MenuItemModel item) {
    if (state.containsKey(item.id)) {
      state[item.id]!.quantity++;
      state = {...state};
    } else {
      state = {
        ...state,
        item.id: CartItem(item: item),
      };
    }
  }

  void removeItem(MenuItemModel item) {
    if (state.containsKey(item.id)) {
      if (state[item.id]!.quantity > 1) {
        state[item.id]!.quantity--;
        state = {...state};
      } else {
        final newState = Map<String, CartItem>.from(state);
        newState.remove(item.id);
        state = newState;
      }
    }
  }

  void clearCart() {
    state = {};
  }

  double get totalAmount {
    double total = 0.0;
    state.forEach((key, cartItem) {
      total += cartItem.item.price * cartItem.quantity;
    });
    return total;
  }

  int get itemCount => state.values.fold(0, (sum, item) => sum + item.quantity);
}

final cartProvider = StateNotifierProvider<CartNotifier, Map<String, CartItem>>((ref) {
  return CartNotifier();
});
