import 'package:get/get.dart';

import '../../../../core/data/datasources/firestore_datasource.dart';
import '../../data/repositories/study_time_repository_impl.dart';
import '../../domain/usecases/get_kelompok_members_usecase.dart';
import '../../domain/usecases/load_study_time_records_usecase.dart';
import '../../domain/usecases/save_study_time_usecase.dart';

/// Dependency Injection Binding for Study Time Feature
/// Note: StudyTimeController is at lib/app/modules/study_time/study_time_controller.dart
/// This binding only registers use cases. Controller registration is handled separately.
class StudyTimeBinding extends Bindings {
  @override
  void dependencies() {
    // Register datasources (shared)
    if (!Get.isRegistered<FirestoreDataSource>()) {
      Get.lazyPut<FirestoreDataSource>(() => FirestoreDataSource());
    }

    // Register repository
    Get.lazyPut(
      () => StudyTimeRepositoryImpl(
        firestoreDataSource: Get.find<FirestoreDataSource>(),
      ),
    );

    // Register use cases
    Get.lazyPut(
      () => SaveStudyTimeUseCase(Get.find<StudyTimeRepositoryImpl>()),
    );
    Get.lazyPut(
      () => LoadStudyTimeRecordsUseCase(Get.find<StudyTimeRepositoryImpl>()),
    );
    Get.lazyPut(
      () => GetKelompokMembersUseCase(Get.find<StudyTimeRepositoryImpl>()),
    );

    // Note: Controller is registered in the old location for backward compatibility
    // Once controller is migrated, uncomment above lines
  }
}
