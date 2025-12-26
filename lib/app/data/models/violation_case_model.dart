import 'package:cloud_firestore/cloud_firestore.dart';

class ViolationCaseModel {
  final String id;
  final String userId;
  final String userDisplayName;
  final int kelompokId;
  final String ruleId;
  final String ruleName;
  final String category;
  final String? timeDetail; // nullable untuk sholat
  final DateTime recordedAt;
  final String recordedBy; // admin userId

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

  factory ViolationCaseModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return ViolationCaseModel(
      id: documentId,
      userId: map['user_id'] ?? '',
      userDisplayName: map['user_display_name'] ?? '',
      kelompokId: map['kelompok_id'] ?? 0,
      ruleId: map['rule_id'] ?? '',
      ruleName: map['rule_name'] ?? '',
      category: map['category'] ?? '',
      timeDetail: map['time_detail'],
      recordedAt:
          (map['recorded_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      recordedBy: map['recorded_by'] ?? '',
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
}
