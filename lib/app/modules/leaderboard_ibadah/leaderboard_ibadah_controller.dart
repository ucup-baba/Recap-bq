import 'package:get/get.dart';

import '../../core/utils/logger.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firestore_service.dart';

class LeaderboardIbadahController extends GetxController {
  final _firestore = FirestoreService.instance;
  final _authService = AuthService.instance;

  // Level-based leaderboard data (hanya amalan, tanpa push-up)
  final RxList<Map<String, dynamic>> levelLeaderboard =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoadingLevelLeaderboard = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Clear any existing data first
    levelLeaderboard.clear();
    isLoadingLevelLeaderboard.value = false;
    _logUserRole();
    loadLevelLeaderboard();
  }

  @override
  void onReady() {
    super.onReady();
    // Note: Data already loaded in onInit(), no need to reload here
    // This prevents double loading and race conditions
    Logger.info('LeaderboardIbadahController onReady - data already loaded');
  }

  @override
  void onClose() {
    // Clear data when controller is closed
    Logger.info('LeaderboardIbadahController onClose - clearing data');
    levelLeaderboard.clear();
    super.onClose();
  }

  void _logUserRole() {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        _firestore.fetchUser(user.uid).then((userModel) {
          final role = userModel?.role ?? 'unknown';
          Logger.info(
            'LeaderboardIbadahController created for user role: $role',
          );
        }).catchError((e) {
          Logger.warning('Error fetching user role: $e');
        });
      } else {
        Logger.warning('No current user when creating LeaderboardIbadahController');
      }
    } catch (e) {
      Logger.warning('Error logging user role: $e');
    }
  }

  /// Load level-based leaderboard (ranking amalan ketua kelompok 1-5)
  Future<void> loadLevelLeaderboard() async {
    try {
      // Clear existing data first
      levelLeaderboard.clear();
      isLoadingLevelLeaderboard.value = true;
      Logger.info('Loading level-based leaderboard...');

      final leaderboard = await _firestore.getLevelBasedLeaderboard();
      Logger.info(
        'Loaded ${leaderboard.length} entries in leaderboard',
      );
      if (leaderboard.isNotEmpty) {
        Logger.info(
          'Top 3: ${leaderboard.take(3).map((e) => '${e['displayName']}: ${e['avgLevel']}%').join(', ')}',
        );
        // Log all entries for debugging
        Logger.info('All entries:');
        for (var entry in leaderboard) {
          Logger.info(
            '  - ${entry['displayName']}: ${entry['avgLevel']}%, pushups: ${entry['totalPushups']}',
          );
        }
      } else {
        Logger.warning('Leaderboard is empty!');
      }
      levelLeaderboard.value = leaderboard;
    } catch (e) {
      Logger.error('Error loading level leaderboard', e);
      levelLeaderboard.value = [];
    } finally {
      isLoadingLevelLeaderboard.value = false;
    }
  }
}
