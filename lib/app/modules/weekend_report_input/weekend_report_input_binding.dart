import 'package:get/get.dart';

import 'weekend_report_input_controller.dart';

class WeekendReportInputBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WeekendReportInputController>(
      () => WeekendReportInputController(),
    );
  }
}
