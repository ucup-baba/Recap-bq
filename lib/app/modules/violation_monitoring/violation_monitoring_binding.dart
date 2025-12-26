import 'package:get/get.dart';

import 'violation_monitoring_controller.dart';

class ViolationMonitoringBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ViolationMonitoringController());
  }
}

