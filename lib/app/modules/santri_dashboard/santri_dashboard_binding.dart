import 'package:get/get.dart';

import '../../controllers/theme_controller.dart';
import '../leaderboard/leaderboard_controller.dart';
import 'santri_dashboard_controller.dart';

class SantriDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SantriDashboardController>(() => SantriDashboardController());
    Get.lazyPut<LeaderboardController>(() => LeaderboardController());
    // Ensure ThemeController is available (may already be registered globally)
    if (!Get.isRegistered<ThemeController>()) {
      Get.put(ThemeController());
    }
  }
}
