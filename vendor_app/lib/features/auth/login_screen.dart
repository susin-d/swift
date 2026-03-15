import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vendor_app/features/auth/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const _teal = Color(0xFF0D9488);
  static const _tealDark = Color(0xFF065F46);

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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    HapticFeedback.lightImpact();
    if (_formKey.currentState!.validate()) {
      ref.read(authProvider.notifier).login(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_teal.withValues(alpha: 0.06), Colors.white, _teal.withValues(alpha: 0.1)],
                ),
              ),
            ),
          ),
          Positioned(top: -100, right: -80, child: Container(width: 280, height: 280, decoration: BoxDecoration(shape: BoxShape.circle, color: _teal.withValues(alpha: 0.06)))),
          Positioned(bottom: -60, left: -60, child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: _teal.withValues(alpha: 0.08)))),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 60),
                        // Brand Mark
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [_teal, _tealDark]),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: _teal.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 8))],
                              ),
                              child: const Icon(Icons.storefront_rounded, size: 30, color: Colors.white),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Swift Vendor',
                              style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, color: _teal, letterSpacing: -1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 60),
                        Text(
                          'Welcome Back',
                          style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A), letterSpacing: -1.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Manage your campus business.',
                          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 60),

                        // Email
                        _buildLabel('EMAIL'),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: 'e.g. vendor@campus.edu',
                            prefixIcon: const Icon(Icons.alternate_email_rounded, color: _teal),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[300]!)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[300]!)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _teal, width: 2)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Email is required';
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Password
                        _buildLabel('PASSWORD'),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: _teal),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.grey[400]),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[300]!)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[300]!)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _teal, width: 2)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          ),
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Password is required';
                            if (v.length < 6) return 'At least 6 characters';
                            return null;
                          },
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  title: Text('Reset Password', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
                                  content: const Text('Contact admin@swift.campus to reset your vendor password.'),
                                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                                ),
                              );
                            },
                            child: Text('Forgot password?', style: GoogleFonts.inter(color: _teal, fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (authState.error != null) ...[
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(authState.error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                            ),
                          ),
                        ],

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: authState.isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _teal,
                              foregroundColor: Colors.white,
                              elevation: 8,
                              shadowColor: _teal.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18),
                            ),
                            child: authState.isLoading
                                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                                : const Text('Login'),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey[300])),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text('OR', style: GoogleFonts.inter(color: Colors.grey[400], fontWeight: FontWeight.w600, fontSize: 12)),
                            ),
                            Expanded(child: Divider(color: Colors.grey[300])),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Demo Button
                        Center(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: _teal.withValues(alpha: 0.4), width: 1.5),
                            ),
                            child: TextButton.icon(
                              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14)),
                              onPressed: authState.isLoading
                                  ? null
                                  : () {
                                      HapticFeedback.lightImpact();
                                      ref.read(authProvider.notifier).login('anna@bhawan.com', 'password123');
                                    },
                              icon: const Icon(Icons.storefront_outlined, size: 20, color: _teal),
                              label: Text('Login as Demo Vendor', style: GoogleFonts.outfit(color: _teal, fontWeight: FontWeight.w800, fontSize: 15)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
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
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(text, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey[500], letterSpacing: 1.5)),
    );
  }
}
