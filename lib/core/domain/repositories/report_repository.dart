import '../entities/report.dart';

/// Abstract Report Repository Interface
/// Defines contract for report data operations
abstract class ReportRepository {
  /// Get report by ID
  Future<DailyReport?> getReportById(String reportId);

  /// Save a daily report
  Future<void> saveDailyReport(DailyReport report);

  /// Get pending reports stream
  Stream<List<DailyReport>> getPendingReports();

  /// Get verified reports
  Future<List<DailyReport>> getVerifiedReports();

  /// Get reports by date
  Future<List<DailyReport>> getReportsByDate(DateTime date);

  /// Get reports by group and date
  Stream<List<DailyReport>> getReportsByGroupAndDate(
    int kelompokId,
    DateTime date,
  );

  /// Update report status
  Future<void> updateReportStatus(String reportId, String status);

  /// Update task validation within a report
  Future<void> updateTaskValidation(
    String reportId,
    int taskIndex, {
    bool? isValid,
    String? adminNote,
  });

  /// Delete multiple reports
  Future<void> deleteReports(List<String> reportIds);

  /// Batch update scores (final_score, group_score, personal_points, streak)
  Future<void> batchUpdateScores({
    required String reportId,
    required int kelompokId,
    required int finalScore,
    required Map<String, int> executorTaskCount,
    bool hasAllTeamTask = false,
    required bool incrementStreak,
  });
}
