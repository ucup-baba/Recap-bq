import 'package:get/get.dart';

import 'santri_dashboard_controller.dart';

class SantriDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SantriDashboardController>(() => SantriDashboardController());
  }
}
