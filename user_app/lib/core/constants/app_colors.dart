import 'package:flutter/material.dart';

class AppColors {
  // Emerald / teal accent system
  static const Color primary = Color(0xFF0FB9A8);
  static const Color primaryLight = Color(0xFF63E6D5);
  static const Color primaryDark = Color(0xFF0A7F74);
  static const Color primaryContainer = Color(0xFFEAFBF8);
  
  // White-mode neutrals
  static const Color background = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color inputBackground = Color(0xFFF3F6F8);
  
  // Text System
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
  
  // Status System
  static const Color success = Color(0xFF10B981);
  static const Color info = Color(0xFF3B82F6);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  
  // Glassmorphism & Translucency
  static const Color whiteGlass = Color(0xF5FFFFFF);
  static const Color blackGlass = Color(0x99000000);
  static const Color border = Color(0x120F172A);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );
}
