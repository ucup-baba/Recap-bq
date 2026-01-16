import '../../../../core/domain/entities/report.dart';
import '../../../../core/domain/repositories/report_repository.dart';

/// Use Case: Submit Daily Report
class SubmitDailyReportUseCase {
  final ReportRepository reportRepository;

  SubmitDailyReportUseCase(this.reportRepository);

  /// Submit a daily report with validation
  Future<void> call({
    required DateTime date,
    required int kelompokId,
    required String slot,
    required List<DailyTask> tasks,
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
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final id = '${dateStr}_${kelompokId}_$slot';

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
