import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class CartEmptyView extends StatelessWidget {
  const CartEmptyView({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_basket_outlined, size: 80, color: AppColors.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 24),
          const Text(
            'Your basket is empty',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add some delicious items from our vendors!',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: onBack,
            child: const Text('BACK TO MENU'),
          ),
        ],
      ),
    );
  }
}
