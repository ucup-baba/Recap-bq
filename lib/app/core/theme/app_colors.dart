import 'package:flutter/material.dart';

/// Centralized color palette based on the design system.
class AppColors {
  static const Color primaryBlue = Color(0xFF2962FF);
  static const Color successGreen = Color(0xFF00C853);
  static const Color alertRed = Color(0xFFD50000);
  static const Color background = Color(0xFFF5F5F5);
  static const Color card = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF212121);

  // Gradient Colors (New UI)
  static const Color gradientStart = Color(0xFFFF8A80); // Red Accent 100
  static const Color gradientEnd = Color(0xFFFF5252); // Red Accent 200
  static const Color orangeAccent = Color(0xFFFF9E80);

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFFFF8A80), Color(0xFFFF5252)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Extension untuk Color dengan helper method yang tidak deprecated
extension ColorExtension on Color {
  /// Helper untuk mendapatkan color dengan opacity (menggunakan withValues)
  Color withAlphaValue(double opacity) {
    return withValues(alpha: opacity);
  }
}
