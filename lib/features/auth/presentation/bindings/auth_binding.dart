import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../../../core/data/datasources/firestore_datasource.dart';
import '../../../../core/domain/repositories/user_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/watch_auth_state_usecase.dart';
import '../controllers/auth_controller.dart';

/// Import UserRepositoryImpl when it's created
// For now, we'll need a temporary UserRepositoryImpl
import '../../../../core/data/repositories/user_repository_impl.dart';

/// Dependency Injection Binding for Auth Feature
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Register datasources (shared)
    if (!Get.isRegistered<FirestoreDataSource>()) {
      Get.lazyPut<FirestoreDataSource>(() => FirestoreDataSource());
    }

    // Register UserRepository (needed by AuthRepository)
    if (!Get.isRegistered<UserRepository>()) {
      Get.lazyPut<UserRepository>(
        () => UserRepositoryImpl(
          firestoreDataSource: Get.find<FirestoreDataSource>(),
        ),
      );
    }

    // Register AuthRepository
    Get.lazyPut(
      () => AuthRepositoryImpl(
        firebaseAuth: FirebaseAuth.instance,
        userRepository: Get.find<UserRepository>(),
      ),
    );

    // Register use cases
    Get.lazyPut(() => SignInWithEmailUseCase(Get.find<AuthRepositoryImpl>()));
    Get.lazyPut(() => SignOutUseCase(Get.find<AuthRepositoryImpl>()));
    Get.lazyPut(() => GetCurrentUserUseCase(Get.find<AuthRepositoryImpl>()));
    Get.lazyPut(() => WatchAuthStateUseCase(Get.find<AuthRepositoryImpl>()));

    // Register controller
    Get.lazyPut<AuthController>(
      () => AuthController(
        signInUseCase: Get.find<SignInWithEmailUseCase>(),
        signOutUseCase: Get.find<SignOutUseCase>(),
        getCurrentUserUseCase: Get.find<GetCurrentUserUseCase>(),
      ),
    );
  }
}
