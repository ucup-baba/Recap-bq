import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../../../core/data/datasources/firestore_datasource.dart';
import '../../../../core/data/datasources/storage_datasource.dart';
import '../../data/repositories/memorable_repository_impl.dart';
import '../../domain/usecases/delete_place_usecase.dart';
import '../../domain/usecases/load_places_usecase.dart';
import '../../domain/usecases/save_place_usecase.dart';
import '../controllers/memorable_controller.dart';

/// Dependency Injection Binding for Memorable Feature
class MemorableBinding extends Bindings {
  @override
  void dependencies() {
    // Register datasources (shared, could be in core binding)
    if (!Get.isRegistered<FirestoreDataSource>()) {
      Get.lazyPut<FirestoreDataSource>(() => FirestoreDataSource());
    }
    if (!Get.isRegistered<StorageDataSource>()) {
      Get.lazyPut<StorageDataSource>(() => StorageDataSource());
    }

    // Register repository
    Get.lazyPut(
      () => MemorableRepositoryImpl(
        firestoreDataSource: Get.find<FirestoreDataSource>(),
        storageDataSource: Get.find<StorageDataSource>(),
      ),
    );

    // Register use cases
    Get.lazyPut(() => SavePlaceUseCase(Get.find<MemorableRepositoryImpl>()));
    Get.lazyPut(() => LoadPlacesUseCase(Get.find<MemorableRepositoryImpl>()));
    Get.lazyPut(() => DeletePlaceUseCase(Get.find<MemorableRepositoryImpl>()));

    // Get current user ID
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Register controller
    Get.lazyPut<MemorableController>(
      () => MemorableController(
        savePlaceUseCase: Get.find<SavePlaceUseCase>(),
        loadPlacesUseCase: Get.find<LoadPlacesUseCase>(),
        deletePlaceUseCase: Get.find<DeletePlaceUseCase>(),
        currentUserId: currentUserId,
      ),
    );
  }
}
