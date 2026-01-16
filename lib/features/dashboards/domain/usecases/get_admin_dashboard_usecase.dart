import '../../../../core/domain/repositories/group_repository.dart';
import '../../../../core/domain/repositories/report_repository.dart';
import '../../../../core/domain/repositories/user_repository.dart';

/// Use Case: Get Admin Dashboard Data
class GetAdminDashboardUseCase {
  final UserRepository userRepository;
  final ReportRepository reportRepository;
  final GroupRepository groupRepository;

  GetAdminDashboardUseCase({
    required this.userRepository,
    required this.reportRepository,
    required this.groupRepository,
  });

  /// Get dashboard data for admin
  Future<Map<String, dynamic>> call() async {
    // Get all groups with scores
    final groups = await groupRepository.getAllGroups();

    // Get pending reports count (using stream, convert to future)
    final pendingReportsStream = reportRepository.watchPendingReports();
    final pendingReports = await pendingReportsStream.first;

    // Get today's reports
    final today = DateTime.now();
    final todayReports = await reportRepository.getReportsByDate(today);

    return {
      'groups': groups,
      'pendingReportsCount': pendingReports.length,
      'pendingReports': pendingReports.take(10).toList(),
      'todayReportsCount': todayReports.length,
      'todayReports': todayReports,
    };
  }
}
