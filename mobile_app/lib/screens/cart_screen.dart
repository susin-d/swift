import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/providers/cart_provider.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _processing = false;
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // 1. Verify payment on backend
    final verifyRes = await http.post(
      Uri.parse('http://localhost:3000/api/v1/payments/verify'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ref.read(supabaseClientProvider).auth.currentSession?.accessToken}',
      },
      body: jsonEncode({
        'razorpay_order_id': response.orderId,
        'razorpay_payment_id': response.paymentId,
        'razorpay_signature': response.signature,
      }),
    );

    if (verifyRes.statusCode == 200) {
      await _finalizeOrder();
    } else {
      _showError('Payment verification failed');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _showError('Payment failed: ${response.message}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _showError('External wallet selected: ${response.walletName}');
  }

  void _showError(String msg) {
    setState(() => _processing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  Future<void> _startPayment() async {
    setState(() => _processing = true);
    try {
      final cart = ref.read(cartProvider);
      
      // 1. Create Razorpay Order via Backend
      final orderRes = await http.post(
        Uri.parse('http://localhost:3000/api/v1/payments/create-order'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ref.read(supabaseClientProvider).auth.currentSession?.accessToken}',
        },
        body: jsonEncode({'amount': cart.totalAmount}),
      );

      if (orderRes.statusCode != 200) throw 'Failed to create payment order';
      
      final orderData = jsonDecode(orderRes.body);

      var options = {
        'key': 'rzp_test_placeholder', // Should come from config
        'amount': orderData['amount'],
        'name': 'Campus Bites',
        'description': 'Food Order',
        'order_id': orderData['id'],
        'prefill': {
          'email': ref.read(currentUserProvider)?.email,
        },
        'theme': {'color': '#0D9488'}
      };

      _razorpay.open(options);
    } catch (e) {
      _showError('Checkout error: $e');
    }
  }

  Future<void> _finalizeOrder() async {
    try {
      final cart = ref.read(cartProvider);
      final supabase = ref.read(supabaseClientProvider);
      
      final response = await supabase.from('orders').insert({
        'vendor_id': cart.vendorId,
        'user_id': supabase.auth.currentUser!.id,
        'total_amount': cart.totalAmount,
        'status': 'pending',
      }).select().single();

      final orderId = response['id'];
      
      final orderItems = cart.items.map((item) => {
        'order_id': orderId,
        'item_id': item.id,
        'quantity': item.quantity,
        'unit_price': item.price,
      }).toList();

      await supabase.from('order_items').insert(orderItems);

      ref.read(cartProvider.notifier).clear();
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Order Placed!'),
            content: const Text('Payment successful and order sent to vendor.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Great!'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _showError('Order finalization failed: $e');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Your Cart', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: cart.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[300]),
                   const SizedBox(height: 16),
                   Text('Your cart is empty', style: GoogleFonts.poppins(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              itemCount: cart.items.length,
              itemBuilder: (context, index) {
                final item = cart.items[index];
                return ListTile(
                  title: Text(item.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  subtitle: Text('₹${item.price} x ${item.quantity}'),
                  trailing: Text('₹${item.price * item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  leading: IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    onPressed: () => ref.read(cartProvider.notifier).removeItem(item.id),
                  ),
                );
              },
            ),
      bottomNavigationBar: cart.items.isEmpty ? null : Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.between,
              children: [
                Text('Total Amount', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('₹${cart.totalAmount}', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF0D9488))),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _processing ? null : _startPayment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _processing 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('PAY NOW', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

