import '../../../../core/domain/repositories/group_repository.dart';
import '../../../../core/domain/repositories/report_repository.dart';
import '../../../../core/domain/repositories/user_repository.dart';

/// Use Case: Get Santri Dashboard Data
class GetSantriDashboardUseCase {
  final UserRepository userRepository;
  final ReportRepository reportRepository;
  final GroupRepository groupRepository;

  GetSantriDashboardUseCase({
    required this.userRepository,
    required this.reportRepository,
    required this.groupRepository,
  });

  /// Get dashboard data for a santri
  Future<Map<String, dynamic>> call(String userId) async {
    if (userId.trim().isEmpty) {
      throw ArgumentError('User ID cannot be empty');
    }

    // Get user data
    final user = await userRepository.getUserById(userId);
    if (user == null) {
      throw Exception('User not found');
    }

    // Get group data if user has kelompok
    final group = user.kelompokId != null
        ? await groupRepository.getGroupById(user.kelompokId!)
        : null;

    // Get recent reports for the user's kelompok
    final recentReports = user.kelompokId != null
        ? await reportRepository.getReportsByKelompok(user.kelompokId!)
        : [];

    return {
      'user': user,
      'group': group,
      'totalPoints': user.stats.totalPoin,
      'currentStreak': user.stats.currentStreak,
      'groupScore': group?.totalWeeklyScore ?? 0,
      'recentReports': recentReports.take(5).toList(),
    };
  }
}
