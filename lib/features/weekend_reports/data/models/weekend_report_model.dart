import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../app/data/models/task_model.dart';
import '../../domain/entities/weekend_report.dart';

/// Weekend Report Model (DTO)
class WeekendReportModel {
  final String id;
  final DateTime weekendDate;
  final int kelompokId;
  final String slot;
  final String reportType;
  final String area;
  final List<TaskModel> tasks;
  final String? photoUrl;
  final String status;
  final DateTime? createdAt;
  final DateTime? submittedAt;
  final DateTime? validatedAt;
  final String? validatedBy;
  final String? rejectionReason;
  final int? finalScore;

  const WeekendReportModel({
    required this.id,
    required this.weekendDate,
    required this.kelompokId,
    required this.slot,
    required this.reportType,
    required this.area,
    required this.tasks,
    this.photoUrl,
    required this.status,
    this.createdAt,
    this.submittedAt,
    this.validatedAt,
    this.validatedBy,
    this.rejectionReason,
    this.finalScore,
  });

  factory WeekendReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse tasks
    List<TaskModel> parsedTasks;
    if (data['tasks'] is List && (data['tasks'] as List).isNotEmpty) {
      parsedTasks = (data['tasks'] as List)
          .map((t) => TaskModel.fromMap(t as Map<String, dynamic>))
          .toList();
    } else {
      parsedTasks = [];
    }

    return WeekendReportModel(
      id: doc.id,
      weekendDate: (data['weekendDate'] as Timestamp).toDate(),
      kelompokId: data['kelompokId'] as int,
      slot: data['slot'] as String,
      reportType: data['reportType'] as String,
      area: data['area'] as String,
      tasks: parsedTasks,
      photoUrl: data['photoUrl'] as String?,
      status: data['status'] as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate(),
      validatedAt: (data['validatedAt'] as Timestamp?)?.toDate(),
      validatedBy: data['validatedBy'] as String?,
      rejectionReason: data['rejectionReason'] as String?,
      finalScore: data['finalScore'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'weekendDate': Timestamp.fromDate(weekendDate),
      'kelompokId': kelompokId,
      'slot': slot,
      'reportType': reportType,
      'area': area,
      'tasks': tasks.map((t) => t.toMap()).toList(),
      'photoUrl': photoUrl,
      'status': status,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'submittedAt': submittedAt != null
          ? Timestamp.fromDate(submittedAt!)
          : null,
      'validatedAt': validatedAt != null
          ? Timestamp.fromDate(validatedAt!)
          : null,
      'validatedBy': validatedBy,
      'rejectionReason': rejectionReason,
      'finalScore': finalScore,
    };
  }

  /// Convert DTO to entity
  WeekendReport toEntity() {
    return WeekendReport(
      id: id,
      weekendDate: weekendDate,
      kelompokId: kelompokId,
      slot: slot,
      reportType: reportType,
      area: area,
      tasks: tasks,
      photoUrl: photoUrl,
      status: status,
      createdAt: createdAt,
      submittedAt: submittedAt,
      validatedAt: validatedAt,
      validatedBy: validatedBy,
      rejectionReason: rejectionReason,
      finalScore: finalScore,
    );
  }

  /// Convert entity to DTO
  static WeekendReportModel fromEntity(WeekendReport entity) {
    return WeekendReportModel(
      id: entity.id,
      weekendDate: entity.weekendDate,
      kelompokId: entity.kelompokId,
      slot: entity.slot,
      reportType: entity.reportType,
      area: entity.area,
      tasks: entity.tasks,
      photoUrl: entity.photoUrl,
      status: entity.status,
      createdAt: entity.createdAt,
      submittedAt: entity.submittedAt,
      validatedAt: entity.validatedAt,
      validatedBy: entity.validatedBy,
      rejectionReason: entity.rejectionReason,
      finalScore: entity.finalScore,
    );
  }
}
