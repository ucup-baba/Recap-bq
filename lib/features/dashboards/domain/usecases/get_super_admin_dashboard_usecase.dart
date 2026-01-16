import '../../../../core/domain/repositories/group_repository.dart';
import '../../../../core/domain/repositories/user_repository.dart';

/// Use Case: Get Super Admin Dashboard Data
class GetSuperAdminDashboardUseCase {
  final UserRepository userRepository;
  final GroupRepository groupRepository;

  GetSuperAdminDashboardUseCase({
    required this.userRepository,
    required this.groupRepository,
  });

  /// Get comprehensive system statistics
  Future<Map<String, dynamic>> call() async {
    // Get all users
    final allUsers = await userRepository.getAllUsers();

    // Get all groups
    final allGroups = await groupRepository.getAllGroups();

    // Calculate statistics
    final totalUsers = allUsers.length;
    final totalGroups = allGroups.length;
    final totalPoints = allUsers.fold<int>(
      0,
      (sum, user) => sum + user.stats.totalPoin,
    );

    // Calculate average points per user
    final averagePoints = totalUsers > 0
        ? (totalPoints / totalUsers).round()
        : 0;

    // Get top performers
    final topUsers = allUsers.toList()
      ..sort((a, b) => b.stats.totalPoin.compareTo(a.stats.totalPoin));

    // Sort groups by score
    final rankedGroups = allGroups.toList()
      ..sort((a, b) => b.totalWeeklyScore.compareTo(a.totalWeeklyScore));

    return {
      'totalUsers': totalUsers,
      'totalGroups': totalGroups,
      'totalPoints': totalPoints,
      'averagePoints': averagePoints,
      'topUsers': topUsers.take(10).toList(),
      'rankedGroups': rankedGroups,
    };
  }
}
