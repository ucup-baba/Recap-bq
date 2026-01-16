import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/study_time_record.dart';

/// Study Time Model (DTO)
/// Handles conversion between Firestore documents and domain entities

class StudyTimeModel {
  final String id;
  final String date;
  final int kelompokId;
  final String recordedBy;
  final DateTime? recordedAt;
  final List<StudyAttendanceModel> attendances;

  const StudyTimeModel({
    required this.id,
    required this.date,
    required this.kelompokId,
    required this.recordedBy,
    this.recordedAt,
    required this.attendances,
  });

  /// Convert from Firestore document to DTO
  factory StudyTimeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudyTimeModel(
      id: doc.id,
      date: data['date'] ?? '',
      kelompokId: data['kelompokId'] ?? 0,
      recordedBy: data['recordedBy'] ?? '',
      recordedAt: (data['recordedAt'] as Timestamp?)?.toDate(),
      attendances:
          (data['attendances'] as List<dynamic>?)
              ?.map(
                (e) => StudyAttendanceModel.fromMap(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  /// Convert DTO to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'date': date,
      'kelompokId': kelompokId,
      'recordedBy': recordedBy,
      'recordedAt': FieldValue.serverTimestamp(),
      'attendances': attendances.map((e) => e.toMap()).toList(),
    };
  }

  /// Convert DTO to domain entity
  StudyTimeRecord toEntity() {
    return StudyTimeRecord(
      id: id,
      date: date,
      kelompokId: kelompokId,
      recordedBy: recordedBy,
      recordedAt: recordedAt,
      attendances: attendances.map((e) => e.toEntity()).toList(),
    );
  }

  /// Convert domain entity to DTO
  static StudyTimeModel fromEntity(StudyTimeRecord entity) {
    return StudyTimeModel(
      id: entity.id,
      date: entity.date,
      kelompokId: entity.kelompokId,
      recordedBy: entity.recordedBy,
      recordedAt: entity.recordedAt,
      attendances: entity.attendances
          .map((e) => StudyAttendanceModel.fromEntity(e))
          .toList(),
    );
  }
}

/// Study Attendance Model (DTO for individual attendance)
class StudyAttendanceModel {
  final String userId;
  final String displayName;
  final String status; // Stored as string in Firestore
  final String? note;

  const StudyAttendanceModel({
    required this.userId,
    required this.displayName,
    required this.status,
    this.note,
  });

  factory StudyAttendanceModel.fromMap(Map<String, dynamic> map) {
    return StudyAttendanceModel(
      userId: map['userId'] ?? '',
      displayName: map['displayName'] ?? '',
      status: map['status'] ?? 'hadir',
      note: map['note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'status': status,
      if (note != null && note!.isNotEmpty) 'note': note,
    };
  }

  /// Convert DTO to domain entity
  StudyAttendance toEntity() {
    return StudyAttendance(
      userId: userId,
      displayName: displayName,
      status: _parseStatus(status),
      note: note,
    );
  }

  /// Convert domain entity to DTO
  static StudyAttendanceModel fromEntity(StudyAttendance entity) {
    return StudyAttendanceModel(
      userId: entity.userId,
      displayName: entity.displayName,
      status: entity.status.name,
      note: entity.note,
    );
  }

  /// Parse status string to enum
  static AttendanceStatus _parseStatus(String status) {
    return AttendanceStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => AttendanceStatus.hadir,
    );
  }
}
