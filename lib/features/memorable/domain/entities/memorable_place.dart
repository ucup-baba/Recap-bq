import 'package:flutter/material.dart';

/// Category enum for memorable places
enum MemorableCategory { masjid, wisata, toko, rumah }

/// Extension for category display and icons
extension MemorableCategoryExtension on MemorableCategory {
  String get label {
    switch (this) {
      case MemorableCategory.masjid:
        return 'Masjid';
      case MemorableCategory.wisata:
        return 'Wisata';
      case MemorableCategory.toko:
        return 'Toko/Warung';
      case MemorableCategory.rumah:
        return 'Rumah';
    }
  }

  IconData get icon {
    switch (this) {
      case MemorableCategory.masjid:
        return Icons.mosque;
      case MemorableCategory.wisata:
        return Icons.landscape;
      case MemorableCategory.toko:
        return Icons.storefront;
      case MemorableCategory.rumah:
        return Icons.home;
    }
  }

  Color get color {
    switch (this) {
      case MemorableCategory.masjid:
        return Colors.green;
      case MemorableCategory.wisata:
        return Colors.blue;
      case MemorableCategory.toko:
        return Colors.orange;
      case MemorableCategory.rumah:
        return Colors.purple;
    }
  }

  static MemorableCategory fromString(String? value) {
    switch (value) {
      case 'masjid':
        return MemorableCategory.masjid;
      case 'wisata':
        return MemorableCategory.wisata;
      case 'toko':
        return MemorableCategory.toko;
      case 'rumah':
        return MemorableCategory.rumah;
      default:
        return MemorableCategory.wisata;
    }
  }
}

/// Memorable Place Entity (Domain Layer)
/// Pure Dart class with no external dependencies
class MemorablePlace {
  final String id;
  final String name;
  final String? description;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final MemorableCategory category;
  final String? photoUrl;
  final DateTime createdAt;
  final String createdBy;

  const MemorablePlace({
    required this.id,
    required this.name,
    this.description,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.category = MemorableCategory.wisata,
    this.photoUrl,
    required this.createdAt,
    required this.createdBy,
  });

  /// Create a copy with updated fields
  MemorablePlace copyWith({
    String? id,
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    double? accuracy,
    MemorableCategory? category,
    String? photoUrl,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return MemorablePlace(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      category: category ?? this.category,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  /// Format coordinates for display
  String get formattedCoordinates =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MemorablePlace && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
