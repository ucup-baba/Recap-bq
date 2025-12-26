import 'package:get/get.dart';

import '../../core/utils/logger.dart';
import 'leaderboard_ibadah_controller.dart';

class LeaderboardIbadahBinding extends Bindings {
  @override
  void dependencies() {
    // Force delete existing controller to ensure fresh data
    // Use force: true to ensure complete removal even if permanent
    try {
      // Always try to delete, even if not registered
      Logger.info('Attempting to delete existing LeaderboardIbadahController');
      Get.delete<LeaderboardIbadahController>(force: true);
    } catch (e) {
      // Ignore errors if controller doesn't exist - that's fine
      Logger.debug('Controller may not exist (this is OK): $e');
    }

    // Create new controller instance
    Logger.info('Creating new LeaderboardIbadahController instance');
    // Use put instead of lazyPut to ensure controller is created immediately
    // permanent: false means it will be deleted when route is removed
    Get.put<LeaderboardIbadahController>(
      LeaderboardIbadahController(),
      permanent: false,
    );
  }
}
