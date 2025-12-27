import 'package:cloud_firestore/cloud_firestore.dart';

import 'task_model.dart';

/// Model for weekend report (Masak + Piket) - aligned with weekday DailyReportModel
class WeekendReportModel {
  final String id;
  final DateTime weekendDate; // Saturday date
  final int kelompokId;
  final String
  slot; // 'sabtu_pagi', 'sabtu_malam', 'ahad_pagi', 'ahad_malam', 'dapur'
  final String reportType; // 'masak', 'piket_sabtu', 'piket_ahad'
  final String area; // Piket area (Halaman, Kamar Aula, etc.) or 'Masak'

  // Tasks with executor info (same as weekday)
  final List<TaskModel> tasks;

  // Photo evidence
  final String? photoUrl;

  // Status tracking
  final String status; // 'draft', 'submitted', 'validated', 'rejected'
  final DateTime createdAt;
  final DateTime? submittedAt;
  final DateTime? validatedAt;
  final String? validatedBy;
  final String? rejectionReason;

  // Scoring (like weekday)
  final int? finalScore;

  WeekendReportModel({
    required this.id,
    required this.weekendDate,
    required this.kelompokId,
    required this.slot,
    required this.reportType,
    required this.area,
    required this.tasks,
    this.photoUrl,
    required this.status,
    required this.createdAt,
    this.submittedAt,
    this.validatedAt,
    this.validatedBy,
    this.rejectionReason,
    this.finalScore,
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
    // Handle both old format (checklist) and new format (tasks)
    List<TaskModel> parsedTasks;
    if (json['tasks'] is List &&
        (json['tasks'] as List).isNotEmpty &&
        json['tasks'][0] is Map) {
      // New format: List<TaskModel>
      parsedTasks = (json['tasks'] as List)
          .map((t) => TaskModel.fromMap(t as Map<String, dynamic>))
          .toList();
    } else if (json['checklist'] != null) {
      // Old format: Map<String, bool> - convert to TaskModel
      final checklist = Map<String, bool>.from(json['checklist'] as Map);
      final taskNames = json['taskNames'] as List? ?? checklist.keys.toList();
      parsedTasks = taskNames
          .map(
            (name) => TaskModel(
              taskName: name.toString(),
              isDone: checklist[name] ?? false,
              executors: [],
            ),
          )
          .toList();
    } else {
      parsedTasks = [];
    }

    return WeekendReportModel(
      id: json['id'] as String,
      weekendDate: (json['weekendDate'] as Timestamp).toDate(),
      kelompokId: json['kelompokId'] as int,
      slot: json['slot'] as String,
      reportType: json['reportType'] as String,
      area: json['area'] as String,
      tasks: parsedTasks,
      photoUrl: json['photoUrl'] as String?,
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
      finalScore: json['finalScore'] as int?,
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
      'tasks': tasks.map((t) => t.toMap()).toList(),
      'photoUrl': photoUrl,
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
      'finalScore': finalScore,
    };
  }

  WeekendReportModel copyWith({
    String? id,
    DateTime? weekendDate,
    int? kelompokId,
    String? slot,
    String? reportType,
    String? area,
    List<TaskModel>? tasks,
    String? photoUrl,
    String? status,
    DateTime? createdAt,
    DateTime? submittedAt,
    DateTime? validatedAt,
    String? validatedBy,
    String? rejectionReason,
    int? finalScore,
  }) {
    return WeekendReportModel(
      id: id ?? this.id,
      weekendDate: weekendDate ?? this.weekendDate,
      kelompokId: kelompokId ?? this.kelompokId,
      slot: slot ?? this.slot,
      reportType: reportType ?? this.reportType,
      area: area ?? this.area,
      tasks: tasks ?? this.tasks,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      submittedAt: submittedAt ?? this.submittedAt,
      validatedAt: validatedAt ?? this.validatedAt,
      validatedBy: validatedBy ?? this.validatedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      finalScore: finalScore ?? this.finalScore,
    );
  }

  /// Calculate completion percentage
  double get completionPercentage {
    if (tasks.isEmpty) return 0.0;
    final completed = tasks.where((t) => t.isDone).length;
    return completed / tasks.length;
  }

  /// Check if all tasks are completed
  bool get isComplete => completionPercentage == 1.0;

  /// Check if report is submitted
  bool get isSubmitted => status == 'submitted' || status == 'validated';

  /// Check if report is validated
  bool get isValidated => status == 'validated';

  /// Check if report is pending validation
  bool get isPending => status == 'submitted';

  /// Get count of completed tasks
  int get completedTaskCount => tasks.where((t) => t.isDone).length;

  /// Get count of valid tasks (after admin validation)
  int get validTaskCount => tasks.where((t) => t.isValid == true).length;
}
