import 'package:get/get.dart';

import 'kedisiplinan_ibadah_controller.dart';

class KedisiplinanIbadahBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => KedisiplinanIbadahController());
  }
}
