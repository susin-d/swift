import 'package:flutter/material.dart';

enum PaymentMethod { payNow, payOnPickup }

class PaymentSheet extends StatelessWidget {
  const PaymentSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose payment method', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.credit_card_rounded),
              title: const Text('Pay now (Razorpay)'),
              subtitle: const Text('Cards, UPI, or wallets'),
              onTap: () => Navigator.pop(context, PaymentMethod.payNow),
            ),
            ListTile(
              leading: const Icon(Icons.payments_rounded),
              title: const Text('Pay on pickup'),
              subtitle: const Text('Settle when you receive your order'),
              onTap: () => Navigator.pop(context, PaymentMethod.payOnPickup),
            ),
          ],
        ),
      ),
    );
  }
}
