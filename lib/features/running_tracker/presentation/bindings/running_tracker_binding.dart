import 'package:get/get.dart';

import '../../../../core/data/datasources/firestore_datasource.dart';
import '../../data/repositories/running_tracker_repository_impl.dart';
import '../../domain/usecases/save_running_log_usecase.dart';

/// Dependency Injection Binding for Running Tracker Feature
class RunningTrackerBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<FirestoreDataSource>()) {
      Get.lazyPut<FirestoreDataSource>(() => FirestoreDataSource());
    }

    Get.lazyPut(
      () => RunningTrackerRepositoryImpl(
        firestoreDataSource: Get.find<FirestoreDataSource>(),
      ),
    );

    Get.lazyPut(
      () => SaveRunningLogUseCase(Get.find<RunningTrackerRepositoryImpl>()),
    );
  }
}
