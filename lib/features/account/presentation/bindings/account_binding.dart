import 'package:get/get.dart';

import '../../../../core/data/repositories/user_repository_impl.dart';
import '../../../../core/domain/repositories/user_repository.dart';
import '../../domain/usecases/manage_account_usecase.dart';

/// Dependency Injection Binding for Account Feature
class AccountBinding extends Bindings {
  @override
  void dependencies() {
    // Register shared repository if not already registered
    if (!Get.isRegistered<UserRepository>()) {
      Get.lazyPut<UserRepository>(() => Get.find<UserRepositoryImpl>());
    }

    // Register use case
    Get.lazyPut(() => ManageAccountUseCase(Get.find<UserRepository>()));
  }
}
