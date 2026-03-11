import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/cart_item_widget.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Your Basket'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: cart.isEmpty
          ? _buildEmptyCart(context)
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: cart.length,
                    itemBuilder: (context, index) {
                      final item = cart.values.toList()[index];
                      return CartItemWidget(
                        item: item.item,
                        quantity: item.quantity,
                        onIncrement: () => cartNotifier.addItem(item.item),
                        onDecrement: () => cartNotifier.removeItem(item.item),
                      );
                    },
                  ),
                ),
                _buildSummary(context, ref),
              ],
            ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_basket_outlined, size: 80, color: AppColors.textMuted.withOpacity(0.5)),
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
            onPressed: () => context.pop(),
            child: const Text('BACK TO MENU'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context, WidgetRef ref) {
    final total = ref.watch(cartProvider.notifier).totalAmount;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subtotal',
                  style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
                Text(
                  '₹${total.toInt()}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fee',
                  style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
                Text(
                  'FREE',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(color: AppColors.border),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
                ),
                Text(
                  '₹${total.toInt()}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 32, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _checkout(context, ref),
                child: const Text('PLACE ORDER'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkout(BuildContext context, WidgetRef ref) async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    final firstItem = cart.values.first;
    
    try {
      final order = await ref.read(orderServiceProvider).placeOrder(
        vendorId: firstItem.item.menuId, // Simplified for now
        items: cart.values.map((i) => {
          'menu_item_id': i.item.id,
          'quantity': i.quantity,
          'unit_price': i.item.price,
        }).toList(),
        totalAmount: ref.read(cartProvider.notifier).totalAmount,
      );

      ref.read(cartProvider.notifier).clearCart();
      context.push('/order-status/${order.id}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkout failed: $e'), backgroundColor: AppColors.error),
      );
    }
  }
}
