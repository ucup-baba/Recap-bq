import 'package:get/get.dart';

import 'kedisiplinan_dashboard_controller.dart';

class KedisiplinanDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => KedisiplinanDashboardController());
  }
}
