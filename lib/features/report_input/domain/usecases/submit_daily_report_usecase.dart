import '../../../../app/data/models/task_model.dart';
import '../../../core/domain/entities/report.dart';
import '../../../core/domain/repositories/report_repository.dart';

/// Use Case: Submit Daily Report
class SubmitDailyReportUseCase {
  final ReportRepository reportRepository;

  SubmitDailyReportUseCase(this.reportRepository);

  /// Submit a daily report with validation
  Future<void> call({
    required String date,
    required int kelompokId,
    required String slot,
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

    if (slot.trim().isEmpty) {
      throw ArgumentError('Slot cannot be empty');
    }

    // Validate slot
    final validSlots = ['pagi', 'malam'];
    if (!validSlots.contains(slot.toLowerCase())) {
      throw ArgumentError('Invalid slot. Must be "pagi" or "malam"');
    }

    // Generate report ID
    final id = '${date}_${kelompokId}_$slot';

    // Create report
    final report = DailyReport(
      id: id,
      date: date,
      kelompokId: kelompokId,
      slot: slot,
      tasks: tasks,
      photoUrl: photoUrl,
      status: 'submitted',
      createdAt: DateTime.now(),
      submittedAt: DateTime.now(),
    );

    // Save to repository
    await reportRepository.saveReport(report);
  }
}
