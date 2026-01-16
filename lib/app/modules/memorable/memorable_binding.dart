import 'package:get/get.dart';
import 'memorable_controller.dart';

class MemorableBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MemorableController>(() => MemorableController());
  }
}
