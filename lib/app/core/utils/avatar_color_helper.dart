import 'package:flutter/material.dart';

/// Utility class for generating consistent avatar colors based on name
class AvatarColorHelper {
  // Predefined avatar colors
  static const List<Color> _avatarColors = [
    Color(0xFF2196F3), // Blue
    Color(0xFFE53935), // Red
    Color(0xFFFFB300), // Yellow/Orange
    Color(0xFF8E24AA), // Purple
    Color(0xFF4CAF50), // Green
    Color(0xFFFF6F00), // Deep Orange
    Color(0xFF00ACC1), // Cyan
    Color(0xFFE91E63), // Pink
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
