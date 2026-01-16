import 'package:get/get.dart';

import '../../../violations/data/repositories/violation_repository_impl.dart';
import '../../../violations/domain/repositories/violation_repository.dart';
import '../../../violations/domain/usecases/manage_violation_rules_usecase.dart';

/// Dependency Injection Binding for Manage Violation Rules Feature
/// Reuses ViolationRepository and ManageViolationRulesUseCase
class ManageViolationRulesBinding extends Bindings {
  @override
  void dependencies() {
    // Register violation repository if not already registered
    if (!Get.isRegistered<ViolationRepository>()) {
      Get.lazyPut<ViolationRepository>(
        () => Get.find<ViolationRepositoryImpl>(),
      );
    }

    // Reuse existing ManageViolationRulesUseCase
    if (!Get.isRegistered<ManageViolationRulesUseCase>()) {
      Get.lazyPut(
        () => ManageViolationRulesUseCase(Get.find<ViolationRepository>()),
      );
    }
  }
}
