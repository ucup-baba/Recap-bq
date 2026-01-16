import 'package:get/get.dart';

import '../../domain/usecases/admin_ibadah_usecase.dart';

/// Dependency Injection Binding for Admin Ibadah Feature
class AdminIbadahBinding extends Bindings {
  @override
  void dependencies() {
    // Register use case
    Get.lazyPut(() => AdminIbadahUseCase());
  }
}
