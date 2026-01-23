import 'package:get/get.dart';
import 'user_management_controller.dart';

/// User Management Binding for dependency injection
class UserManagementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UserManagementController>(() => UserManagementController());
  }
}
