import 'package:get/get.dart';

import 'running_tracker_controller.dart';

class RunningTrackerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RunningTrackerController>(() => RunningTrackerController());
  }
}
