import 'package:get/get.dart';

import 'manage_violation_rules_controller.dart';

class ManageViolationRulesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ManageViolationRulesController());
  }
}
