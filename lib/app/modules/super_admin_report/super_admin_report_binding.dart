import 'package:get/get.dart';

import 'super_admin_report_controller.dart';

class SuperAdminReportBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SuperAdminReportController>(
      () => SuperAdminReportController(),
    );
  }
}

