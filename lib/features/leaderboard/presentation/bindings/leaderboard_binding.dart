import 'package:get/get.dart';

import '../../../../core/data/repositories/group_repository_impl.dart';
import '../../../../core/data/repositories/user_repository_impl.dart';
import '../../../../core/domain/repositories/group_repository.dart';
import '../../../../core/domain/repositories/user_repository.dart';
import '../../domain/usecases/get_leaderboard_usecase.dart';

/// Dependency Injection Binding for Leaderboard Feature
class LeaderboardBinding extends Bindings {
  @override
  void dependencies() {
    // Register shared repositories if not already registered
    if (!Get.isRegistered<GroupRepository>()) {
      Get.lazyPut<GroupRepository>(() => Get.find<GroupRepositoryImpl>());
    }

    if (!Get.isRegistered<UserRepository>()) {
      Get.lazyPut<UserRepository>(() => Get.find<UserRepositoryImpl>());
    }

    // Register use case
    Get.lazyPut(
      () => GetLeaderboardUseCase(
        groupRepository: Get.find<GroupRepository>(),
        userRepository: Get.find<UserRepository>(),
      ),
    );
  }
}
