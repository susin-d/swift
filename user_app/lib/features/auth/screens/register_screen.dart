import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../providers/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    HapticFeedback.lightImpact();
    if (_formKey.currentState!.validate()) {
      ref.read(authNotifierProvider.notifier).signUp(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    ref.listen<AsyncValue<void>>(authNotifierProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
        data: (_) {
          if (previous?.isLoading == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Registration successful!'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        },
      );
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [AppColors.primary.withValues(alpha: 0.05), Colors.white, AppColors.primary.withValues(alpha: 0.1)],
                ),
              ),
            ),
          ),
          Positioned(bottom: -80, right: -80, child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withValues(alpha: 0.06)))),
          Positioned(top: 40, left: -30, child: Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withValues(alpha: 0.04)))),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  children: [
                    // Top Navigation
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
                            onPressed: () => context.pop(),
                          ),
                          const SizedBox(width: 8),
                          Text('Join Swift', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        ],
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              Text(AppStrings.createAccount, style: Theme.of(context).textTheme.displayLarge),
                              const SizedBox(height: 12),
                              Text(
                                'Experience the future of campus dining.',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 60),

                              // Form Section
                              _buildLabel('FULL NAME'),
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(hintText: 'e.g. Alex Johnson', prefixIcon: Icon(Icons.person_rounded)),
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Name is required';
                                  if (v.trim().length < 2) return 'At least 2 characters';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              _buildLabel('CAMPUS EMAIL'),
                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(hintText: 'e.g. alex@campus.edu', prefixIcon: Icon(Icons.alternate_email_rounded)),
                                keyboardType: TextInputType.emailAddress,
                                autocorrect: false,
                                textInputAction: TextInputAction.next,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Email is required';
                                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) return 'Enter a valid email';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              _buildLabel('PASSWORD'),
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  hintText: 'Min. 8 characters',
                                  prefixIcon: const Icon(Icons.lock_person_rounded),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: AppColors.textMuted),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Password is required';
                                  if (v.length < 8) return 'At least 8 characters';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 48),

                              if (authState.hasError)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 24),
                                    child: Text(
                                      authState.error.toString(),
                                      style: const TextStyle(color: AppColors.error, fontSize: 14, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),

                              // Action Button
                              SizedBox(
                                width: double.infinity,
                                height: 64,
                                child: ElevatedButton(
                                  onPressed: authState.isLoading ? null : _submit,
                                  child: authState.isLoading
                                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                                      : const Text(AppStrings.register),
                                ),
                              ),
                              const SizedBox(height: 40),

                              Center(
                                child: Column(
                                  children: [
                                    Text('By signing up, you agree to our', style: Theme.of(context).textTheme.bodySmall),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        GestureDetector(
                                          onTap: () => context.push('/legal'),
                                          child: _buildLinkText('Terms of Service'),
                                        ),
                                        const Text(' & '),
                                        GestureDetector(
                                          onTap: () => context.push('/privacy'),
                                          child: _buildLinkText('Privacy Policy'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 60),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textSecondary.withValues(alpha: 0.8), letterSpacing: 1.5)),
    );
  }

  Widget _buildLinkText(String text) {
    return Text(text, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12, decoration: TextDecoration.underline));
  }
}
