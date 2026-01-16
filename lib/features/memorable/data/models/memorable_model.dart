import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/memorable_place.dart';

/// Data Transfer Object (DTO) for Memorable Place
/// Handles conversion between Firestore and domain entity
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

  /// Convert to domain entity
  MemorablePlace toEntity() {
    return MemorablePlace(
      id: id,
      name: name,
      description: description,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      category: category,
      photoUrl: photoUrl,
      createdAt: createdAt,
      createdBy: createdBy,
    );
  }

  /// Create from domain entity
  factory MemorableModel.fromEntity(MemorablePlace entity) {
    return MemorableModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      latitude: entity.latitude,
      longitude: entity.longitude,
      accuracy: entity.accuracy,
      category: entity.category,
      photoUrl: entity.photoUrl,
      createdAt: entity.createdAt,
      createdBy: entity.createdBy,
    );
  }
}
