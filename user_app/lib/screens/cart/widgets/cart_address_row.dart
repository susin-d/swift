import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/address_model.dart';

class CartAddressRow extends StatelessWidget {
  const CartAddressRow({
    super.key,
    required this.addressesAsync,
    required this.defaultAddress,
    required this.hasAddress,
    required this.onManageAddress,
  });

  final AsyncValue<List<AddressModel>> addressesAsync;
  final AddressModel defaultAddress;
  final bool hasAddress;
  final VoidCallback onManageAddress;

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: addressesAsync.when(
              loading: () => const Text('Loading address...', style: TextStyle(fontWeight: FontWeight.w700)),
              error: (_, _) => const Text(
                'Address book unavailable right now. You can still place the order.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              data: (_) => hasAddress
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          defaultAddress.label,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          defaultAddress.addressLine,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    )
                  : const Text(
                      'Add a delivery address to place your order.',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
          TextButton(
            onPressed: onManageAddress,
            child: Text(hasAddress ? 'Change' : 'Add'),
          ),
        ],
      ),
    );
  }
}
