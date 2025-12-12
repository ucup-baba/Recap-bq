import 'package:get/get.dart';

import 'manage_tasks_controller.dart';

class ManageTasksBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ManageTasksController>(() => ManageTasksController());
  }
}
