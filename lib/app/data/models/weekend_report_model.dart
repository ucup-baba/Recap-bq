import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for weekend report (Masak + Piket)
class WeekendReportModel {
  final String id;
  final DateTime weekendDate; // Saturday date
  final int kelompokId;
  final String
  slot; // 'sabtu_pagi', 'sabtu_malam', 'ahad_pagi', 'ahad_malam', 'dapur'
  final String reportType; // 'masak', 'piket_sabtu', 'piket_ahad'
  final String area; // Piket area (Halaman, Kamar Aula, etc.) or 'Masak'

  // Task checklist
  final List<String> tasks;
  final Map<String, bool> checklist;

  // Photo evidence
  final String? photoUrl;

  // Executor info
  final String? executorId;
  final String? executorName;

  // Status tracking
  final String status; // 'draft', 'submitted', 'validated', 'rejected'
  final DateTime createdAt;
  final DateTime? submittedAt;
  final DateTime? validatedAt;
  final String? validatedBy;
  final String? rejectionReason;

  WeekendReportModel({
    required this.id,
    required this.weekendDate,
    required this.kelompokId,
    required this.slot,
    required this.reportType,
    required this.area,
    required this.tasks,
    required this.checklist,
    this.photoUrl,
    this.executorId,
    this.executorName,
    required this.status,
    required this.createdAt,
    this.submittedAt,
    this.validatedAt,
    this.validatedBy,
    this.rejectionReason,
  });

  /// Generate document ID: {weekendDate}_{kelompokId}_{reportType}
  static String generateId(
    DateTime weekendDate,
    int kelompokId,
    String reportType,
  ) {
    final dateStr =
        '${weekendDate.year}-${weekendDate.month.toString().padLeft(2, '0')}-${weekendDate.day.toString().padLeft(2, '0')}';
    return '${dateStr}_${kelompokId}_$reportType';
  }

  factory WeekendReportModel.fromJson(Map<String, dynamic> json) {
    return WeekendReportModel(
      id: json['id'] as String,
      weekendDate: (json['weekendDate'] as Timestamp).toDate(),
      kelompokId: json['kelompokId'] as int,
      slot: json['slot'] as String,
      reportType: json['reportType'] as String,
      area: json['area'] as String,
      tasks: List<String>.from(json['tasks'] as List),
      checklist: Map<String, bool>.from(json['checklist'] as Map),
      photoUrl: json['photoUrl'] as String?,
      executorId: json['executorId'] as String?,
      executorName: json['executorName'] as String?,
      status: json['status'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      submittedAt: json['submittedAt'] != null
          ? (json['submittedAt'] as Timestamp).toDate()
          : null,
      validatedAt: json['validatedAt'] != null
          ? (json['validatedAt'] as Timestamp).toDate()
          : null,
      validatedBy: json['validatedBy'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'weekendDate': Timestamp.fromDate(weekendDate),
      'kelompokId': kelompokId,
      'slot': slot,
      'reportType': reportType,
      'area': area,
      'tasks': tasks,
      'checklist': checklist,
      'photoUrl': photoUrl,
      'executorId': executorId,
      'executorName': executorName,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'submittedAt': submittedAt != null
          ? Timestamp.fromDate(submittedAt!)
          : null,
      'validatedAt': validatedAt != null
          ? Timestamp.fromDate(validatedAt!)
          : null,
      'validatedBy': validatedBy,
      'rejectionReason': rejectionReason,
    };
  }

  WeekendReportModel copyWith({
    String? id,
    DateTime? weekendDate,
    int? kelompokId,
    String? slot,
    String? reportType,
    String? area,
    List<String>? tasks,
    Map<String, bool>? checklist,
    String? photoUrl,
    String? executorId,
    String? executorName,
    String? status,
    DateTime? createdAt,
    DateTime? submittedAt,
    DateTime? validatedAt,
    String? validatedBy,
    String? rejectionReason,
  }) {
    return WeekendReportModel(
      id: id ?? this.id,
      weekendDate: weekendDate ?? this.weekendDate,
      kelompokId: kelompokId ?? this.kelompokId,
      slot: slot ?? this.slot,
      reportType: reportType ?? this.reportType,
      area: area ?? this.area,
      tasks: tasks ?? this.tasks,
      checklist: checklist ?? this.checklist,
      photoUrl: photoUrl ?? this.photoUrl,
      executorId: executorId ?? this.executorId,
      executorName: executorName ?? this.executorName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      submittedAt: submittedAt ?? this.submittedAt,
      validatedAt: validatedAt ?? this.validatedAt,
      validatedBy: validatedBy ?? this.validatedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  /// Calculate completion percentage
  double get completionPercentage {
    if (tasks.isEmpty) return 0.0;
    final completed = checklist.values.where((v) => v).length;
    return completed / tasks.length;
  }

  /// Check if all tasks are completed
  bool get isComplete => completionPercentage == 1.0;

  /// Check if report is submitted
  bool get isSubmitted => status == 'submitted' || status == 'validated';

  /// Check if report is validated
  bool get isValidated => status == 'validated';
}
