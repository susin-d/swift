import 'package:flutter/material.dart';

class AppColors {
  // Premium Emerald/Teal System
  static const Color primary = Color(0xFF00BFA5); // Vibrant Teal
  static const Color primaryLight = Color(0xFF64FFDA); // Light Aquamarine
  static const Color primaryDark = Color(0xFF00796B); // Deep Emerald
  static const Color primaryContainer = Color(0xFFE0F2F1);
  
  // Sophisticated Neutral System
  static const Color background = Color(0xFFF1F5F9); // Light Slate
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color inputBackground = Color(0xFFE2E8F0);
  
  // Text System
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400
  
  // Status System
  static const Color success = Color(0xFF10B981);
  static const Color info = Color(0xFF3B82F6);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  
  // Glassmorphism & Translucency
  static const Color whiteGlass = Color(0xCCFFFFFF);
  static const Color blackGlass = Color(0x99000000);
  static const Color border = Color(0x1F000000);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );
}
