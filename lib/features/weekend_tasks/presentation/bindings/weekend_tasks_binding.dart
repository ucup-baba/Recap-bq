import 'package:get/get.dart';

import '../../../../core/data/datasources/firestore_datasource.dart';
import '../../data/repositories/weekend_tasks_repository_impl.dart';
import '../../domain/usecases/manage_weekend_tasks_usecase.dart';

/// Dependency Injection Binding for Weekend Tasks Feature
class WeekendTasksBinding extends Bindings {
  @override
  void dependencies() {
    // Register datasources (shared)
    if (!Get.isRegistered<FirestoreDataSource>()) {
      Get.lazyPut<FirestoreDataSource>(() => FirestoreDataSource());
    }

    // Register repository
    Get.lazyPut(
      () => WeekendTasksRepositoryImpl(
        firestoreDataSource: Get.find<FirestoreDataSource>(),
      ),
    );

    // Register use case
    Get.lazyPut(
      () => ManageWeekendTasksUseCase(Get.find<WeekendTasksRepositoryImpl>()),
    );
  }
}
