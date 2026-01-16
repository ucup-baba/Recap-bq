import 'package:get/get.dart';

import '../../../core/data/repositories/group_repository_impl.dart';
import '../../../core/data/repositories/report_repository_impl.dart';
import '../../../core/data/repositories/user_repository_impl.dart';
import '../../../core/domain/repositories/group_repository.dart';
import '../../../core/domain/repositories/report_repository.dart';
import '../../../core/domain/repositories/user_repository.dart';
import '../../../violations/data/repositories/violation_repository_impl.dart';
import '../../../violations/domain/repositories/violation_repository.dart';
import '../../domain/usecases/get_statistics_usecase.dart';

/// Dependency Injection Binding for Statistics Feature
class StatisticsBinding extends Bindings {
  @override
  void dependencies() {
    // Register shared repositories if not already registered
    if (!Get.isRegistered<UserRepository>()) {
      Get.lazyPut<UserRepository>(() => Get.find<UserRepositoryImpl>());
    }

    if (!Get.isRegistered<GroupRepository>()) {
      Get.lazyPut<GroupRepository>(() => Get.find<GroupRepositoryImpl>());
    }

    if (!Get.isRegistered<ReportRepository>()) {
      Get.lazyPut<ReportRepository>(() => Get.find<ReportRepositoryImpl>());
    }

    if (!Get.isRegistered<ViolationRepository>()) {
      Get.lazyPut<ViolationRepository>(
        () => Get.find<ViolationRepositoryImpl>(),
      );
    }

    // Register use case
    Get.lazyPut(
      () => GetStatisticsUseCase(
        userRepository: Get.find<UserRepository>(),
        groupRepository: Get.find<GroupRepository>(),
        reportRepository: Get.find<ReportRepository>(),
        violationRepository: Get.find<ViolationRepository>(),
      ),
    );
  }
}
