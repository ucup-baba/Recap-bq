import '../entities/report.dart';

/// Abstract Report Repository Interface
/// Defines contract for report data operations
abstract class ReportRepository {
  /// Save a report (daily report)
  Future<void> saveReport(DailyReport report);

  /// Get report by ID
  Future<DailyReport?> getReportById(String reportId);

  /// Get reports by date
  Future<List<DailyReport>> getReportsByDate(DateTime date);

  /// Get reports by kelompok
  Future<List<DailyReport>> getReportsByKelompok(int kelompokId);

  /// Watch pending reports (real-time stream)
  Stream<List<DailyReport>> watchPendingReports();

  /// Update report status
  Future<void> updateReportStatus({
    required String reportId,
    required String status,
    String? validatedBy,
    String? rejectionReason,
  });

  /// Batch update scores (report + group + users)
  Future<void> batchUpdateScores({
    required String reportId,
    required int kelompokId,
    required int finalScore,
    required Map<String, int> executorTaskCount,
    required bool incrementStreak,
  });
}
