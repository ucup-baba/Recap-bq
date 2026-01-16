/// Base Report Entity
/// Abstract class for all report types
abstract class Report {
  final String id;
  final int kelompokId;
  final DateTime date;
  final String status; // 'pending', 'verified', 'rejected'
  final int finalScore;

  const Report({
    required this.id,
    required this.kelompokId,
    required this.date,
    required this.status,
    this.finalScore = 0,
  });

  bool get isPending => status == 'pending';
  bool get isVerified => status == 'verified';
  bool get isRejected => status == 'rejected';
}

/// Daily Report Entity
class DailyReport extends Report {
  final String? photoUrl;
  final List<DailyTask> tasks;
  final String? adminNote;

  const DailyReport({
    required super.id,
    required super.kelompokId,
    required super.date,
    required super.status,
    super.finalScore,
    this.photoUrl,
    required this.tasks,
    this.adminNote,
  });

  DailyReport copyWith({
    String? id,
    int? kelompokId,
    DateTime? date,
    String? status,
    int? finalScore,
    String? photoUrl,
    List<DailyTask>? tasks,
    String? adminNote,
  }) {
    return DailyReport(
      id: id ?? this.id,
      kelompokId: kelompokId ?? this.kelompokId,
      date: date ?? this.date,
      status: status ?? this.status,
      finalScore: finalScore ?? this.finalScore,
      photoUrl: photoUrl ?? this.photoUrl,
      tasks: tasks ?? this.tasks,
      adminNote: adminNote ?? this.adminNote,
    );
  }
}

/// Daily Task Entity (part of Daily Report)
class DailyTask {
  final String areaName;
  final String executor;
  final bool isValid;
  final String? adminNote;

  const DailyTask({
    required this.areaName,
    required this.executor,
    this.isValid = false,
    this.adminNote,
  });

  DailyTask copyWith({
    String? areaName,
    String? executor,
    bool? isValid,
    String? adminNote,
  }) {
    return DailyTask(
      areaName: areaName ?? this.areaName,
      executor: executor ?? this.executor,
      isValid: isValid ?? this.isValid,
      adminNote: adminNote ?? this.adminNote,
    );
  }
}
