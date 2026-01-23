import 'package:get/get.dart';
import 'role_controller.dart';

/// Role Binding for dependency injection
class RoleBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RoleController>(() => RoleController());
  }
}
