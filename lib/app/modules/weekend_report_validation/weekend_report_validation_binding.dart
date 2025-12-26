import 'package:get/get.dart';

import 'weekend_report_validation_controller.dart';

class WeekendReportValidationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WeekendReportValidationController>(
      () => WeekendReportValidationController(),
    );
  }
}
