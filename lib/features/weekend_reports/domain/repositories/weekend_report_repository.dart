import '../entities/weekend_report.dart';

/// Abstract Weekend Report Repository Interface
abstract class WeekendReportRepository {
  /// Save or update a weekend report
  Future<void> saveReport(WeekendReport report);

  /// Get report by ID
  Future<WeekendReport?> getReportById(String id);

  /// Get report for specific kelompok, date, and type
  Future<WeekendReport?> getReport({
    required DateTime weekendDate,
    required int kelompokId,
    required String reportType,
  });

  /// Get all reports for a weekend date
  Future<List<WeekendReport>> getReportsByDate(DateTime weekendDate);

  /// Watch pending reports (real-time)
  Stream<List<WeekendReport>> watchPendingReports();

  /// Update report status
  Future<void> updateReportStatus({
    required String reportId,
    required String status,
    String? validatedBy,
    String? rejectionReason,
    int? finalScore,
  });

  /// Delete a report
  Future<void> deleteReport(String reportId);
}
