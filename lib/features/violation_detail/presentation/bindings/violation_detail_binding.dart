import 'package:get/get.dart';

import '../../../violations/data/repositories/violation_repository_impl.dart';
import '../../../violations/domain/repositories/violation_repository.dart';
import '../../../violations/domain/usecases/get_violation_history_usecase.dart';

/// Dependency Injection Binding for Violation Detail Feature
/// Read-only view of violation details - reuses existing repository and use case
class ViolationDetailBinding extends Bindings {
  @override
  void dependencies() {
    // Register violation repository if not already registered
    if (!Get.isRegistered<ViolationRepository>()) {
      Get.lazyPut<ViolationRepository>(
        () => Get.find<ViolationRepositoryImpl>(),
      );
    }

    // Reuse existing GetViolationHistoryUseCase
    if (!Get.isRegistered<GetViolationHistoryUseCase>()) {
      Get.lazyPut(
        () => GetViolationHistoryUseCase(Get.find<ViolationRepository>()),
      );
    }
  }
}
