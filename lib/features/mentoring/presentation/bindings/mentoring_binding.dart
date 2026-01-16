import 'package:get/get.dart';

import '../../../../core/data/datasources/firestore_datasource.dart';
import '../../data/repositories/mentoring_repository_impl.dart';
import '../../domain/usecases/get_mentoring_history_usecase.dart';
import '../../domain/usecases/save_mentoring_note_usecase.dart';

/// Dependency Injection Binding for Mentoring Feature
class MentoringBinding extends Bindings {
  @override
  void dependencies() {
    // Register datasources (shared)
    if (!Get.isRegistered<FirestoreDataSource>()) {
      Get.lazyPut<FirestoreDataSource>(() => FirestoreDataSource());
    }

    // Register repository
    Get.lazyPut(
      () => MentoringRepositoryImpl(
        firestoreDataSource: Get.find<FirestoreDataSource>(),
      ),
    );

    // Register use cases
    Get.lazyPut(
      () => SaveMentoringNoteUseCase(Get.find<MentoringRepositoryImpl>()),
    );
    Get.lazyPut(
      () => GetMentoringHistoryUseCase(Get.find<MentoringRepositoryImpl>()),
    );
  }
}
