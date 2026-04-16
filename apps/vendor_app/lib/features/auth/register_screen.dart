import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  @override
  Widget build(BuildContext context) {
    // Registration UI removed as requested
    return Scaffold(
      appBar: AppBar(title: const Text('Create Vendor Account')),
      body: const Center(
        child: Text('Vendor registration is currently unavailable.'),
      ),
    );
  }
}


