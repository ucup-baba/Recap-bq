import '../../../core/domain/repositories/group_repository.dart';
import '../../../core/domain/repositories/report_repository.dart';
import '../../../core/domain/repositories/user_repository.dart';
import '../../violations/domain/repositories/violation_repository.dart';

/// Use Case: Get Statistics
class GetStatisticsUseCase {
  final UserRepository userRepository;
  final GroupRepository groupRepository;
  final ReportRepository reportRepository;
  final ViolationRepository violationRepository;

  GetStatisticsUseCase({
    required this.userRepository,
    required this.groupRepository,
    required this.reportRepository,
    required this.violationRepository,
  });

  /// Get comprehensive statistics
  Future<Map<String, dynamic>> getOverallStats() async {
    final allUsers = await userRepository.getAllUsers();
    final allGroups = await groupRepository.getAllGroups();

    final totalPoints = allUsers.fold<int>(
      0,
      (sum, user) => sum + user.stats.totalPoin,
    );

    final totalGroupScore = allGroups.fold<int>(
      0,
      (sum, group) => sum + group.totalWeeklyScore,
    );

    return {
      'totalUsers': allUsers.length,
      'totalGroups': allGroups.length,
      'totalPoints': totalPoints,
      'totalGroupScore': totalGroupScore,
      'averagePointsPerUser': allUsers.isNotEmpty
          ? (totalPoints / allUsers.length).round()
          : 0,
    };
  }

  /// Get statistics for a specific kelompok
  Future<Map<String, dynamic>> getKelompokStats(int kelompokId) async {
    final allUsers = await userRepository.getAllUsers();
    final group = await groupRepository.getGroupById(kelompokId);
    final members = allUsers.where((u) => u.kelompokId == kelompokId).toList();

    final totalMemberPoints = members.fold<int>(
      0,
      (sum, user) => sum + user.stats.totalPoin,
    );

    return {
      'kelompokId': kelompokId,
      'groupScore': group?.totalWeeklyScore ?? 0,
      'memberCount': members.length,
      'totalMemberPoints': totalMemberPoints,
      'averagePointsPerMember': members.isNotEmpty
          ? (totalMemberPoints / members.length).round()
          : 0,
    };
  }
}
