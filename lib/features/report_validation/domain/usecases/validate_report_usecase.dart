import '../../../../core/domain/repositories/group_repository.dart';
import '../../../../core/domain/repositories/report_repository.dart';
import '../../../../core/domain/repositories/user_repository.dart';

/// Use Case: Validate a report (approve/reject)
class ValidateReportUseCase {
  final ReportRepository reportRepository;
  final UserRepository userRepository;
  final GroupRepository groupRepository;

  ValidateReportUseCase({
    required this.reportRepository,
    required this.userRepository,
    required this.groupRepository,
  });

  /// Approve a report and update scores
  Future<void> approve({
    required String reportId,
    required String validatedBy,
    required int finalScore,
    required Map<String, int> executorTaskCount,
  }) async {
    // Validation
    if (reportId.trim().isEmpty) {
      throw ArgumentError('Report ID cannot be empty');
    }

    if (validatedBy.trim().isEmpty) {
      throw ArgumentError('Validator ID cannot be empty');
    }

    if (finalScore < 0) {
      throw ArgumentError('Score cannot be negative');
    }

    // Get report to extract kelompok ID
    final report = await reportRepository.getReportById(reportId);
    if (report == null) {
      throw Exception('Report not found');
    }

    // Update report status
    await reportRepository.updateReportStatus(
      reportId: reportId,
      status: 'validated',
      validatedBy: validatedBy,
    );

    // Batch update scores (report + group + users)
    await reportRepository.batchUpdateScores(
      reportId: reportId,
      kelompokId: report.kelompokId,
      finalScore: finalScore,
      executorTaskCount: executorTaskCount,
      incrementStreak: true,
    );
  }

  /// Reject a report with reason
  Future<void> reject({
    required String reportId,
    required String validatedBy,
    required String rejectionReason,
  }) async {
    // Validation
    if (reportId.trim().isEmpty) {
      throw ArgumentError('Report ID cannot be empty');
    }

    if (validatedBy.trim().isEmpty) {
      throw ArgumentError('Validator ID cannot be empty');
    }

    if (rejectionReason.trim().isEmpty) {
      throw ArgumentError('Rejection reason cannot be empty');
    }

    // Update report status
    await reportRepository.updateReportStatus(
      reportId: reportId,
      status: 'rejected',
      validatedBy: validatedBy,
      rejectionReason: rejectionReason,
    );
  }
}
