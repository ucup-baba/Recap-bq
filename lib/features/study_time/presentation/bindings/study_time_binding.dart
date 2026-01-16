import 'package:get/get.dart';

import '../../../../core/data/datasources/firestore_datasource.dart';
import '../../data/repositories/study_time_repository_impl.dart';
import '../../domain/usecases/get_kelompok_members_usecase.dart';
import '../../domain/usecases/load_study_time_records_usecase.dart';
import '../../domain/usecases/save_study_time_usecase.dart';
import '../controllers/study_time_controller.dart';

/// Dependency Injection Binding for Study Time Feature
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

    // Register controller
    Get.lazyPut<StudyTimeController>(
      () => StudyTimeController(
        saveStudyTimeUseCase: Get.find<SaveStudyTimeUseCase>(),
        loadRecordsUseCase: Get.find<LoadStudyTimeRecordsUseCase>(),
        getMembersUseCase: Get.find<GetKelompokMembersUseCase>(),
      ),
    );
  }
}
