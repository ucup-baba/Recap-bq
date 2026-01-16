import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/violation.dart';

/// Violation Case Model (DTO)
class ViolationCaseModel {
  final String id;
  final String userId;
  final String userDisplayName;
  final int kelompokId;
  final String ruleId;
  final String ruleName;
  final String category;
  final String? timeDetail;
  final DateTime recordedAt;
  final String recordedBy;

  const ViolationCaseModel({
    required this.id,
    required this.userId,
    required this.userDisplayName,
    required this.kelompokId,
    required this.ruleId,
    required this.ruleName,
    required this.category,
    this.timeDetail,
    required this.recordedAt,
    required this.recordedBy,
  });

  factory ViolationCaseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ViolationCaseModel(
      id: doc.id,
      userId: data['user_id'] ?? '',
      userDisplayName: data['user_display_name'] ?? '',
      kelompokId: data['kelompok_id'] ?? 0,
      ruleId: data['rule_id'] ?? '',
      ruleName: data['rule_name'] ?? '',
      category: data['category'] ?? '',
      timeDetail: data['time_detail'],
      recordedAt:
          (data['recorded_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      recordedBy: data['recorded_by'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'user_display_name': userDisplayName,
      'kelompok_id': kelompokId,
      'rule_id': ruleId,
      'rule_name': ruleName,
      'category': category,
      if (timeDetail != null) 'time_detail': timeDetail,
      'recorded_at': Timestamp.fromDate(recordedAt),
      'recorded_by': recordedBy,
    };
  }

  /// Convert DTO to entity
  ViolationCase toEntity() {
    return ViolationCase(
      id: id,
      userId: userId,
      userDisplayName: userDisplayName,
      kelompokId: kelompokId,
      ruleId: ruleId,
      ruleName: ruleName,
      category: category,
      timeDetail: timeDetail,
      recordedAt: recordedAt,
      recordedBy: recordedBy,
    );
  }

  /// Convert entity to DTO
  static ViolationCaseModel fromEntity(ViolationCase entity) {
    return ViolationCaseModel(
      id: entity.id,
      userId: entity.userId,
      userDisplayName: entity.userDisplayName,
      kelompokId: entity.kelompokId,
      ruleId: entity.ruleId,
      ruleName: entity.ruleName,
      category: entity.category,
      timeDetail: entity.timeDetail,
      recordedAt: entity.recordedAt,
      recordedBy: entity.recordedBy,
    );
  }
}

/// Violation Rule Model (DTO)
class ViolationRuleModel {
  final String id;
  final String name;
  final String category;
  final int pointDeduction;
  final bool isActive;

  const ViolationRuleModel({
    required this.id,
    required this.name,
    required this.category,
    required this.pointDeduction,
    this.isActive = true,
  });

  factory ViolationRuleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ViolationRuleModel(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      pointDeduction: data['point_deduction'] ?? 0,
      isActive: data['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'point_deduction': pointDeduction,
      'is_active': isActive,
    };
  }

  /// Convert DTO to entity
  ViolationRule toEntity() {
    return ViolationRule(
      id: id,
      name: name,
      category: category,
      pointDeduction: pointDeduction,
      isActive: isActive,
    );
  }

  /// Convert entity to DTO
  static ViolationRuleModel fromEntity(ViolationRule entity) {
    return ViolationRuleModel(
      id: entity.id,
      name: entity.name,
      category: entity.category,
      pointDeduction: entity.pointDeduction,
      isActive: entity.isActive,
    );
  }
}
