import 'package:flutter/material.dart';

class AppColors {
  // Brand system
  static const Color primary = Color(0xFF0E9F8B);
  static const Color primaryLight = Color(0xFF52D3C0);
  static const Color primaryDark = Color(0xFF0A6C5E);
  static const Color primaryContainer = Color(0xFFDDF7F2);
  static const Color secondary = Color(0xFFFF8B4D);
  static const Color secondaryLight = Color(0xFFFFC39F);
  static const Color accent = Color(0xFF173A63);

  // Surface system
  static const Color background = Color(0xFFF4F7F3);
  static const Color backgroundAlt = Color(0xFFE8EFE9);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color inputBackground = Color(0xFFF8FAFB);
  static const Color shell = Color(0xFFFDFEFE);

  // Typography system
  static const Color textPrimary = Color(0xFF102033);
  static const Color textSecondary = Color(0xFF536274);
  static const Color textMuted = Color(0xFF708090);

  // Status system
  static const Color success = Color(0xFF10B981);
  static const Color info = Color(0xFF3B82F6);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Outline and translucency
  static const Color whiteGlass = Color(0xF5FFFFFF);
  static const Color blackGlass = Color(0x99000000);
  static const Color border = Color(0x14102033);
  static const Color divider = Color(0x1F102033);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0E9F8B), Color(0xFF173A63)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, Color(0xFFFFA874)],
  );
}
