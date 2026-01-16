import 'package:cloud_firestore/cloud_firestore.dart';
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

/// Model for memorable place data
class MemorableModel {
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

  MemorableModel({
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

  /// Create from Firestore document
  factory MemorableModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MemorableModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      accuracy: data['accuracy']?.toDouble(),
      category: MemorableCategoryExtension.fromString(data['category']),
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'category': category.name,
      'photoUrl': photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
    };
  }

  /// Create a copy with updated fields
  MemorableModel copyWith({
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
    return MemorableModel(
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
}
