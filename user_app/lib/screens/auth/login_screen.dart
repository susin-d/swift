import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const SizedBox(height: 100),
            // Logo / Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(Icons.restaurant_rounded, size: 64, color: AppColors.primary),
            ),
            const SizedBox(height: 40),
            Text(
              AppStrings.welcomeBack,
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to your Swift hub',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 60),
            
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
            
            // Login Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: authState.isLoading 
                  ? null 
                  : () => ref.read(authNotifierProvider.notifier).signIn(
                      _emailController.text, 
                      _passwordController.text
                    ),
                child: authState.isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text(AppStrings.login),
              ),
            ),
            const SizedBox(height: 24),
            
            // Register Link
            TextButton(
              onPressed: () => context.push('/register'),
              child: const Text('Create an Account', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}
