import 'package:cloud_firestore/cloud_firestore.dart';

class ViolationRuleModel {
  final String id;
  final String name;
  final String category;
  final bool requiresTimeDetail;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ViolationRuleModel({
    required this.id,
    required this.name,
    required this.category,
    required this.requiresTimeDetail,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ViolationRuleModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return ViolationRuleModel(
      id: documentId,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      requiresTimeDetail: map['requires_time_detail'] ?? false,
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'requires_time_detail': requiresTimeDetail,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  ViolationRuleModel copyWith({
    String? id,
    String? name,
    String? category,
    bool? requiresTimeDetail,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ViolationRuleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      requiresTimeDetail: requiresTimeDetail ?? this.requiresTimeDetail,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
