import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class CartPromoRow extends StatelessWidget {
  const CartPromoRow({
    super.key,
    required this.promoController,
    required this.isApplying,
    required this.message,
    required this.discountAmount,
    required this.appliedPromoCode,
    required this.onApply,
    required this.onRemove,
  });

  final TextEditingController promoController;
  final bool isApplying;
  final String? message;
  final double discountAmount;
  final String? appliedPromoCode;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
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
          const Text('Promo code', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: promoController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'Enter code',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => onApply(),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: isApplying ? null : onApply,
                child: isApplying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Apply'),
              ),
            ],
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message!,
              style: TextStyle(
                color: discountAmount > 0 ? AppColors.primary : AppColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (appliedPromoCode != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Chip(
                  label: Text('Applied: $appliedPromoCode'),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onRemove,
                  child: const Text('Remove'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
