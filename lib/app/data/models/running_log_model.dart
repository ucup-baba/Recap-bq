import 'package:cloud_firestore/cloud_firestore.dart';

/// Model untuk tracking lari harian
class RunningLogModel {
  final String id;
  final String odooId;
  final String odooName;
  final DateTime date;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  RunningLogModel({
    required this.id,
    required this.odooId,
    required this.odooName,
    required this.date,
    required this.isCompleted,
    this.completedAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RunningLogModel.fromMap(Map<String, dynamic> map, String docId) {
    return RunningLogModel(
      id: docId,
      odooId: map['odooId'] as String? ?? '',
      odooName: map['odooName'] as String? ?? '',
      date: (map['date'] as Timestamp).toDate(),
      isCompleted: map['isCompleted'] as bool? ?? false,
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      notes: map['notes'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'odooId': odooId,
      'odooName': odooName,
      'date': Timestamp.fromDate(date),
      'isCompleted': isCompleted,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  RunningLogModel copyWith({
    String? id,
    String? odooId,
    String? odooName,
    DateTime? date,
    bool? isCompleted,
    DateTime? completedAt,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RunningLogModel(
      id: id ?? this.id,
      odooId: odooId ?? this.odooId,
      odooName: odooName ?? this.odooName,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get date string untuk grouping (YYYY-MM-DD)
  String get dateKey {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
