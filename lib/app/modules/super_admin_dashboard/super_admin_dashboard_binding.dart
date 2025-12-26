import 'package:get/get.dart';

import 'super_admin_dashboard_controller.dart';

class SuperAdminDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SuperAdminDashboardController>(
      () => SuperAdminDashboardController(),
    );
  }
}

