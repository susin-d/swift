import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/menu_model.dart';

class CartItemWidget extends StatelessWidget {
  final MenuItemModel item;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const CartItemWidget({
    super.key,
    required this.item,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimary),
                ),
                Text(
                  '₹${(item.price * quantity).toInt()}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.primary),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: onDecrement,
                  icon: const Icon(Icons.remove, size: 18, color: AppColors.primary),
                ),
                Text(
                  quantity.toString(),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                IconButton(
                  onPressed: onIncrement,
                  icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
