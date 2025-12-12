import 'package:get/get.dart';

import 'manage_members_controller.dart';

class ManageMembersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ManageMembersController>(() => ManageMembersController());
  }
}
