import 'package:get/get.dart';

import 'weekend_schedule_controller.dart';

class WeekendScheduleBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WeekendScheduleController>(() => WeekendScheduleController());
  }
}
