import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import 'responsive_content.dart';

class CustomerShell extends StatelessWidget {
  const CustomerShell({
    super.key,
    required this.selectedIndex,
    required this.body,
    this.title,
    this.subtitle,
    this.actions,
    this.showHeader = true,
    this.headerPadding,
    this.bodyPadding,
    this.destinations = _defaultDestinations,
  });

  final int selectedIndex;
  final Widget body;
  final String? title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showHeader;
  final EdgeInsetsGeometry? headerPadding;
  final EdgeInsetsGeometry? bodyPadding;
  final List<ShellDestination> destinations;

  static const List<ShellDestination> _defaultDestinations = [
    ShellDestination(label: 'Home', icon: Icons.home_rounded, route: '/'),
    ShellDestination(
      label: 'Orders',
      icon: Icons.receipt_long_rounded,
      route: '/order-history',
    ),
    ShellDestination(
      label: 'Cart',
      icon: Icons.shopping_bag_rounded,
      route: '/cart',
    ),
    ShellDestination(
      label: 'Profile',
      icon: Icons.person_rounded,
      route: '/profile',
    ),
  ];

  static const List<ShellDestination> primaryDestinations = [
    ShellDestination(label: 'Home', icon: Icons.home_rounded, route: '/'),
    ShellDestination(label: 'Browse', icon: Icons.explore_rounded, route: '/browse'),
    ShellDestination(
      label: 'Orders',
      icon: Icons.receipt_long_rounded,
      route: '/order-history',
    ),
    ShellDestination(
      label: 'Wallet',
      icon: Icons.credit_card_rounded,
      route: '/wallet',
    ),
    ShellDestination(
      label: 'Account',
      icon: Icons.person_rounded,
      route: '/account',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.backgroundAlt, AppColors.background],
          ),
        ),
        child: Stack(
          children: [
            const _ShellBackdrop(),
            SafeArea(
              bottom: false,
              child: ResponsiveContent(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    mediaQuery.padding.bottom + 110,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showHeader)
                        Padding(
                          padding:
                              headerPadding ??
                              const EdgeInsets.fromLTRB(4, 8, 4, 20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (subtitle != null)
                                      Text(
                                        subtitle!,
                                        style: GoogleFonts.inter(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    if (subtitle != null) const SizedBox(height: 6),
                                    if (title != null)
                                      Text(
                                        title!,
                                        style: GoogleFonts.outfit(
                                          color: AppColors.textPrimary,
                                          fontSize: 30,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.8,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (actions != null) ...actions!,
                            ],
                          ),
                        ),
                      Expanded(
                        child: Padding(
                          padding: bodyPadding ?? EdgeInsets.zero,
                          child: body,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        child: _CustomerBottomNav(
          selectedIndex: selectedIndex,
          destinations: destinations,
        ),
      ),
    );
  }
}

class _CustomerBottomNav extends StatelessWidget {
  const _CustomerBottomNav({
    required this.selectedIndex,
    required this.destinations,
  });

  final int selectedIndex;
  final List<ShellDestination> destinations;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.whiteGlass,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Row(
            children: List.generate(destinations.length, (index) {
              final destination = destinations[index];
              final isSelected = index == selectedIndex;

              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    if (isSelected) return;
                    context.go(destination.route);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppColors.heroGradient : null,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          destination.icon,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          destination.label,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _ShellBackdrop extends StatelessWidget {
  const _ShellBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -110,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryLight.withValues(alpha: 0.2),
              ),
            ),
          ),
          Positioned(
            top: 180,
            left: -80,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            right: -40,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.06),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ShellDestination {
  const ShellDestination({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}
