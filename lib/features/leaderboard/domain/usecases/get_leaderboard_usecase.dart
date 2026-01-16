import '../../../core/domain/entities/group.dart';
import '../../../core/domain/repositories/group_repository.dart';
import '../../../core/domain/repositories/user_repository.dart';

/// Use Case: Get Leaderboard
class GetLeaderboardUseCase {
  final GroupRepository groupRepository;
  final UserRepository userRepository;

  GetLeaderboardUseCase({
    required this.groupRepository,
    required this.userRepository,
  });

  /// Get real-time leaderboard stream
  Stream<List<Group>> watchLeaderboard() {
    return groupRepository.watchLeaderboard();
  }

  /// Get static leaderboard snapshot
  Future<List<Group>> getLeaderboard() async {
    final groups = await groupRepository.getAllGroups();
    // Sort by score descending
    groups.sort((a, b) => b.totalWeeklyScore.compareTo(a.totalWeeklyScore));
    return groups;
  }

  /// Get leaderboard with member count enrichment
  Future<List<Map<String, dynamic>>> getEnrichedLeaderboard() async {
    final groups = await getLeaderboard();
    final allUsers = await userRepository.getAllUsers();

    return groups.map((group) {
      final memberCount = allUsers
          .where((user) => user.kelompokId == group.groupId)
          .length;

      return {
        'group': group,
        'memberCount': memberCount,
        'averageScore': memberCount > 0
            ? (group.totalWeeklyScore / memberCount).round()
            : 0,
      };
    }).toList();
  }
}
