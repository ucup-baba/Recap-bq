import 'package:get/get.dart';

import '../../../../core/data/datasources/firestore_datasource.dart';
import '../../data/repositories/violation_repository_impl.dart';
import '../../domain/usecases/get_violation_history_usecase.dart';
import '../../domain/usecases/manage_violation_rules_usecase.dart';
import '../../domain/usecases/record_violation_usecase.dart';

/// Dependency Injection Binding for Violations Feature
class ViolationsBinding extends Bindings {
  @override
  void dependencies() {
    // Register datasources (shared)
    if (!Get.isRegistered<FirestoreDataSource>()) {
      Get.lazyPut<FirestoreDataSource>(() => FirestoreDataSource());
    }

    // Register repository
    Get.lazyPut(
      () => ViolationRepositoryImpl(
        firestoreDataSource: Get.find<FirestoreDataSource>(),
      ),
    );

    // Register use cases
    Get.lazyPut(
      () => RecordViolationUseCase(Get.find<ViolationRepositoryImpl>()),
    );
    Get.lazyPut(
      () => GetViolationHistoryUseCase(Get.find<ViolationRepositoryImpl>()),
    );
    Get.lazyPut(
      () => ManageViolationRulesUseCase(Get.find<ViolationRepositoryImpl>()),
    );
  }
}
