import 'package:get/get.dart';
import 'user_dashboard_controller.dart';

/// User Dashboard Binding for dependency injection
class UserDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UserDashboardController>(() => UserDashboardController());
  }
}
