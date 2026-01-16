import '../../../../app/data/models/task_model.dart';
import '../entities/weekend_report.dart';
import '../repositories/weekend_report_repository.dart';

/// Use Case: Submit Weekend Report
class SubmitWeekendReportUseCase {
  final WeekendReportRepository repository;

  SubmitWeekendReportUseCase(this.repository);

  /// Submit a weekend report with validation
  Future<void> call({
    required DateTime weekendDate,
    required int kelompokId,
    required String slot,
    required String reportType,
    required String area,
    required List<TaskModel> tasks,
    String? photoUrl,
  }) async {
    // Validation
    if (kelompokId < 1) {
      throw ArgumentError('Invalid kelompok ID');
    }

    if (tasks.isEmpty) {
      throw ArgumentError('Tasks cannot be empty');
    }

    if (slot.trim().isEmpty || reportType.trim().isEmpty) {
      throw ArgumentError('Slot and report type are required');
    }

    // Generate report ID
    final id = _generateId(weekendDate, kelompokId, reportType);

    // Create report
    final report = WeekendReport(
      id: id,
      weekendDate: weekendDate,
      kelompokId: kelompokId,
      slot: slot,
      reportType: reportType,
      area: area,
      tasks: tasks,
      photoUrl: photoUrl,
      status: 'submitted',
      createdAt: DateTime.now(),
      submittedAt: DateTime.now(),
    );

    // Save to repository
    await repository.saveReport(report);
  }

  /// Generate document ID: {weekendDate}_{kelompokId}_{reportType}
  String _generateId(DateTime weekendDate, int kelompokId, String reportType) {
    final dateStr =
        '${weekendDate.year}-${weekendDate.month.toString().padLeft(2, '0')}-${weekendDate.day.toString().padLeft(2, '0')}';
    return '${dateStr}_${kelompokId}_$reportType';
  }
}
