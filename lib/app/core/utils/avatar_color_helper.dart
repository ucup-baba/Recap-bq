import 'package:flutter/material.dart';

/// Utility class for generating consistent avatar colors based on name
class AvatarColorHelper {
  // Expanded palette with 16 colors for better variety
  static const List<Color> _avatarColors = [
    Color(0xFF2196F3), // Blue
    Color(0xFFE53935), // Red
    Color(0xFFFFB300), // Amber
    Color(0xFF8E24AA), // Purple
    Color(0xFF4CAF50), // Green
    Color(0xFFFF6F00), // Deep Orange
    Color(0xFF00ACC1), // Cyan
    Color(0xFFE91E63), // Pink
    Color(0xFF3F51B5), // Indigo
    Color(0xFF009688), // Teal
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue Grey
    Color(0xFF673AB7), // Deep Purple
    Color(0xFFCDDC39), // Lime (dark variant for contrast)
    Color(0xFF00BCD4), // Cyan variant
    Color(0xFFF44336), // Red variant
  ];

  /// Get consistent color for a given name
  /// The same name will always return the same color
  static Color getColorForName(String name) {
    if (name.isEmpty) return _avatarColors[0];
    final hash = name.hashCode;
    return _avatarColors[hash.abs() % _avatarColors.length];
  }

  /// Get first letter of name (uppercase)
  static String getInitial(String name) {
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }
}
