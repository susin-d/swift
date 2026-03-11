import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              AppStrings.createAccount,
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Join the Swift community',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 60),
            
            // Name Input
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Full Name',
                prefixIcon: Icon(Icons.person_rounded, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 20),
            
            // Email Input
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                hintText: AppStrings.campusEmail,
                prefixIcon: Icon(Icons.alternate_email_rounded, color: AppColors.primary),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            
            // Password Input
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                hintText: 'Password',
                prefixIcon: Icon(Icons.lock_person_rounded, color: AppColors.primary),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 40),
            
            // Register Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: authState.isLoading 
                  ? null 
                  : () => ref.read(authNotifierProvider.notifier).signUp(
                      _emailController.text, 
                      _passwordController.text,
                      _nameController.text
                    ),
                child: authState.isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text(AppStrings.register),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
