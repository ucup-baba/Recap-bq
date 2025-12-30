import 'package:flutter/material.dart';

/// Centralized color palette based on the design system.
class AppColors {
  // Static colors (don't change with theme)
  static const Color primaryBlue = Color(0xFF2962FF);
  static const Color successGreen = Color(0xFF00C853);
  static const Color alertRed = Color(0xFFD50000);

  // Light mode colors (static, for backwards compatibility)
  static const Color background = Color(0xFFF5F5F5);
  static const Color card = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF212121);

  // Dark mode colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2C2C2C);
  static const Color darkText = Color(0xFFE0E0E0);
  static const Color darkSubtext = Color(0xFFB0B0B0);

  // Gradient Colors (New UI)
  static const Color gradientStart = Color(0xFFFF8A80); // Red Accent 100
  static const Color gradientEnd = Color(0xFFFF5252); // Red Accent 200
  static const Color orangeAccent = Color(0xFFFF9E80);

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFFFF8A80), Color(0xFFFF5252)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ========== Context-aware color getters ==========

  /// Get background color based on current theme
  static Color getBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackground
        : background;
  }

  /// Get card color based on current theme
  static Color getCard(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkCard : card;
  }

  /// Get surface color based on current theme
  static Color getSurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkSurface : card;
  }

  /// Get text color based on current theme
  static Color getText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkText : text;
  }

  /// Get subtext color based on current theme
  static Color getSubtext(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSubtext
        : Colors.grey.shade600;
  }

  /// Check if current theme is dark
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
}

/// Extension untuk Color dengan helper method yang tidak deprecated
extension ColorExtension on Color {
  /// Helper untuk mendapatkan color dengan opacity (menggunakan withValues)
  Color withAlphaValue(double opacity) {
    return withValues(alpha: opacity);
  }
}

/// Extension on BuildContext for easier color access
extension ThemeColorExtension on BuildContext {
  /// Quick access to adaptive colors
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get backgroundColor => AppColors.getBackground(this);
  Color get cardColor => AppColors.getCard(this);
  Color get surfaceColor => AppColors.getSurface(this);
  Color get textColor => AppColors.getText(this);
  Color get subtextColor => AppColors.getSubtext(this);
}
