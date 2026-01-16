import '../repositories/weekend_report_repository.dart';

/// Use Case: Validate Weekend Report
class ValidateWeekendReportUseCase {
  final WeekendReportRepository repository;

  ValidateWeekendReportUseCase(this.repository);

  /// Approve a weekend report
  Future<void> approve({
    required String reportId,
    required String validatedBy,
    required int finalScore,
  }) async {
    if (reportId.trim().isEmpty) {
      throw ArgumentError('Report ID cannot be empty');
    }

    if (validatedBy.trim().isEmpty) {
      throw ArgumentError('Validator ID cannot be empty');
    }

    if (finalScore < 0) {
      throw ArgumentError('Score cannot be negative');
    }

    await repository.updateReportStatus(
      reportId: reportId,
      status: 'validated',
      validatedBy: validatedBy,
      finalScore: finalScore,
    );
  }

  /// Reject a weekend report
  Future<void> reject({
    required String reportId,
    required String validatedBy,
    required String rejectionReason,
  }) async {
    if (reportId.trim().isEmpty) {
      throw ArgumentError('Report ID cannot be empty');
    }

    if (rejectionReason.trim().isEmpty) {
      throw ArgumentError('Rejection reason cannot be empty');
    }

    await repository.updateReportStatus(
      reportId: reportId,
      status: 'rejected',
      validatedBy: validatedBy,
      rejectionReason: rejectionReason,
    );
  }
}
