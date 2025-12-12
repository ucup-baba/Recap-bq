import 'package:get/get.dart';

import 'report_validation_controller.dart';

class ReportValidationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReportValidationController>(() => ReportValidationController());
  }
}
