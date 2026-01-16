import 'package:get/get.dart';

import '../../../../core/data/datasources/firestore_datasource.dart';
import '../../data/repositories/nalya_repository_impl.dart';
import '../../domain/usecases/record_nalya_checkin_usecase.dart';

/// Dependency Injection Binding for Nalya Feature
class NalyaBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<FirestoreDataSource>()) {
      Get.lazyPut<FirestoreDataSource>(() => FirestoreDataSource());
    }

    Get.lazyPut(
      () => NalyaRepositoryImpl(
        firestoreDataSource: Get.find<FirestoreDataSource>(),
      ),
    );

    Get.lazyPut(
      () => RecordNalyaCheckInUseCase(Get.find<NalyaRepositoryImpl>()),
    );
  }
}
