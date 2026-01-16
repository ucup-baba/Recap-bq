import '../entities/group.dart';

/// Abstract Group Repository Interface
/// Defines contract for group data operations
abstract class GroupRepository {
  /// Get group by ID
  Future<Group?> getGroupById(int groupId);

  /// Get all groups
  Future<List<Group>> getAllGroups();

  /// Watch group leaderboard (ordered by total weekly score)
  Stream<List<Group>> watchGroupLeaderboard();

  /// Update group score
  Future<void> updateGroupScore(int groupId, int scoreIncrement);

  /// Reset weekly scores for all groups
  Future<void> resetWeeklyScores();
}
