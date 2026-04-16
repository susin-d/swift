import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:vendor_app/core/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.post(
        '/auth/register-vendor',
        data: {
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'storeName': _storeNameController.text.trim(),
          'phone': _phoneController.text.trim(),
        },
      );
      final data = response.data;
      if (data['success'] == true) {
        if (!mounted) return;
        context.go('/login');
      } else {
        setState(() {
          _error = data['message'] ?? 'Registration failed.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Registration failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Registration UI removed as requested
    return Scaffold(
      appBar: AppBar(title: const Text('Create Vendor Account')),
      body: Center(
        child: Text('Vendor registration is currently unavailable.'),
      ),
    );
  }
}


