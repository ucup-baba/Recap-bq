import 'package:get/get.dart';

import 'manage_weekend_tasks_controller.dart';

class ManageWeekendTasksBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ManageWeekendTasksController>(
      () => ManageWeekendTasksController(),
    );
  }
}
