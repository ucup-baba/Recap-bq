import 'package:get/get.dart';

import '../../../core/data/datasources/firestore_datasource.dart';
import '../../../violations/data/repositories/violation_repository_impl.dart';
import '../../../violations/domain/repositories/violation_repository.dart';
import '../../../violations/domain/usecases/get_violation_history_usecase.dart';

/// Dependency Injection Binding for Violation Monitoring Feature
/// Dashboard view for monitoring all violations
class ViolationMonitoringBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<FirestoreDataSource>()) {
      Get.lazyPut<FirestoreDataSource>(() => FirestoreDataSource());
    }

    if (!Get.isRegistered<ViolationRepository>()) {
      Get.lazyPut<ViolationRepository>(
        () => Get.find<ViolationRepositoryImpl>(),
      );
    }

    if (!Get.isRegistered<GetViolationHistoryUseCase>()) {
      Get.lazyPut(
        () => GetViolationHistoryUseCase(Get.find<ViolationRepository>()),
      );
    }
  }
}
