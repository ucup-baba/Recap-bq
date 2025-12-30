import 'package:get/get.dart';

import 'nalya_checkin_controller.dart';

class NalyaBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NalyaCheckInController>(() => NalyaCheckInController());
  }
}
