import 'package:get/get.dart';
import 'admin_ibadah_controller.dart';

class AdminIbadahBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminIbadahController>(() => AdminIbadahController());
  }
}
