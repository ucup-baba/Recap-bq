import 'package:get/get.dart';

import '../../../core/data/repositories/group_repository_impl.dart';
import '../../../core/data/repositories/report_repository_impl.dart';
import '../../../core/data/repositories/user_repository_impl.dart';
import '../../../core/domain/repositories/group_repository.dart';
import '../../../core/domain/repositories/report_repository.dart';
import '../../../core/domain/repositories/user_repository.dart';
import '../../domain/usecases/validate_report_usecase.dart';

/// Dependency Injection Binding for Report Validation Feature
class ReportValidationBinding extends Bindings {
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

    // Register use case
    Get.lazyPut(
      () => ValidateReportUseCase(
        reportRepository: Get.find<ReportRepository>(),
        userRepository: Get.find<UserRepository>(),
        groupRepository: Get.find<GroupRepository>(),
      ),
    );
  }
}
