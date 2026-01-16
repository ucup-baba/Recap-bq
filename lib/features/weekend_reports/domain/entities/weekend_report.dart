import '../../../../app/data/models/task_model.dart';

/// Weekend Report Domain Entity
/// Pure Dart class with no external dependencies

/// Weekend report for Masak or Piket activities
class WeekendReport {
  final String id;
  final DateTime weekendDate; // Saturday date
  final int kelompokId;
  final String
  slot; // 'sabtu_pagi', 'sabtu_malam', 'ahad_pagi', 'ahad_malam', 'dapur'
  final String reportType; // 'masak', 'piket_sabtu', 'piket_ahad'
  final String area; // Area name or 'Masak'
  final List<TaskModel> tasks;
  final String? photoUrl;
  final String status; // 'draft', 'submitted', 'validated', 'rejected'
  final DateTime? createdAt;
  final DateTime? submittedAt;
  final DateTime? validatedAt;
  final String? validatedBy;
  final String? rejectionReason;
  final int? finalScore;

  const WeekendReport({
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

  WeekendReport copyWith({
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
    return WeekendReport(
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
}
