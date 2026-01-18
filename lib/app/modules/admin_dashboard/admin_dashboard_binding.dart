import 'package:get/get.dart';

import '../admin_ibadah/admin_ibadah_controller.dart';
import '../leaderboard/leaderboard_controller.dart';
import '../manage_members/manage_members_controller.dart';
import '../nalya/nalya_feedback_controller.dart';
import 'admin_dashboard_controller.dart';

class AdminDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminDashboardController>(() => AdminDashboardController());
    Get.lazyPut<AdminIbadahController>(() => AdminIbadahController());
    Get.lazyPut<LeaderboardController>(() => LeaderboardController());
    Get.lazyPut<ManageMembersController>(() => ManageMembersController());
    Get.lazyPut<NalyaFeedbackController>(() => NalyaFeedbackController());
  }
}
