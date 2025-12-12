import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final int groupId;
  final int totalWeeklyScore;
  final DateTime? lastUpdated;

  const GroupModel({
    required this.groupId,
    required this.totalWeeklyScore,
    this.lastUpdated,
  });

  factory GroupModel.fromMap(Map<String, dynamic> map, String documentId) {
    final timestamp = map['last_updated'];
    return GroupModel(
      groupId: map['group_id'] ?? int.tryParse(documentId) ?? 0,
      totalWeeklyScore: map['total_weekly_score'] ?? 0,
      lastUpdated: timestamp is Timestamp
          ? timestamp.toDate()
          : timestamp is DateTime
          ? timestamp
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'group_id': groupId,
      'total_weekly_score': totalWeeklyScore,
      if (lastUpdated != null) 'last_updated': Timestamp.fromDate(lastUpdated!),
    };
  }
}
