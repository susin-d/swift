import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/menu_model.dart';
import '../../../providers/cart_provider.dart';

class CartFoodOrderRow extends StatelessWidget {
  const CartFoodOrderRow({
    super.key,
    required this.cartItems,
    required this.onIncrement,
    required this.onDecrement,
  });

  final List<CartItem> cartItems;
  final ValueChanged<MenuItemModel> onIncrement;
  final ValueChanged<MenuItemModel> onDecrement;

  @override
  Widget build(BuildContext context) {
    final itemCount = cartItems.length;
    final quantityCount = cartItems.fold<int>(0, (sum, item) => sum + item.quantity);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant_menu_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Food order', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      '$itemCount item${itemCount == 1 ? '' : 's'} • $quantityCount total qty',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (cartItems.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 8),
            ...cartItems.map(
              (cartItem) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        cartItem.item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      color: AppColors.textSecondary,
                      visualDensity: VisualDensity.compact,
                      onPressed: () => onDecrement(cartItem.item),
                    ),
                    Text(
                      '${cartItem.quantity}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_rounded),
                      color: AppColors.primary,
                      visualDensity: VisualDensity.compact,
                      onPressed: () => onIncrement(cartItem.item),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
