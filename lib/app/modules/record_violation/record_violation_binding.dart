import 'package:get/get.dart';

import 'record_violation_controller.dart';

class RecordViolationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => RecordViolationController());
  }
}

