import 'package:get/get.dart';

import 'super_admin_account_controller.dart';

class SuperAdminAccountBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SuperAdminAccountController>(
      () => SuperAdminAccountController(),
    );
  }
}

