import 'package:get/get.dart';

import '../../../../core/data/datasources/firestore_datasource.dart';
import '../../../violations/data/repositories/violation_repository_impl.dart';
import '../../../violations/domain/usecases/record_violation_usecase.dart';

/// Dependency Injection Binding for Record Violation Feature
/// Reuses ViolationRepository and RecordViolationUseCase
class RecordViolationBinding extends Bindings {
  @override
  void dependencies() {
    // Register datasources (shared)
    if (!Get.isRegistered<FirestoreDataSource>()) {
      Get.lazyPut<FirestoreDataSource>(() => FirestoreDataSource());
    }

    // Register repository if not already registered
    if (!Get.isRegistered<ViolationRepositoryImpl>()) {
      Get.lazyPut(
        () => ViolationRepositoryImpl(
          firestoreDataSource: Get.find<FirestoreDataSource>(),
        ),
      );
    }

    // Reuse existing RecordViolationUseCase
    if (!Get.isRegistered<RecordViolationUseCase>()) {
      Get.lazyPut(
        () => RecordViolationUseCase(Get.find<ViolationRepositoryImpl>()),
      );
    }
  }
}
