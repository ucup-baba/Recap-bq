import 'package:get/get.dart';

import '../../../core/data/repositories/group_repository_impl.dart';
import '../../../core/data/repositories/report_repository_impl.dart';
import '../../../core/data/repositories/user_repository_impl.dart';
import '../../../core/domain/repositories/group_repository.dart';
import '../../../core/domain/repositories/report_repository.dart';
import '../../../core/domain/repositories/user_repository.dart';
import '../../domain/usecases/get_admin_dashboard_usecase.dart';
import '../../domain/usecases/get_santri_dashboard_usecase.dart';
import '../../domain/usecases/get_super_admin_dashboard_usecase.dart';

/// Unified Dashboard Binding for all dashboard types
/// Register based on user role
class DashboardsBinding extends Bindings {
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

    // Register all dashboard use cases
    Get.lazyPut(
      () => GetSantriDashboardUseCase(
        userRepository: Get.find<UserRepository>(),
        reportRepository: Get.find<ReportRepository>(),
        groupRepository: Get.find<GroupRepository>(),
      ),
    );

    Get.lazyPut(
      () => GetAdminDashboardUseCase(
        userRepository: Get.find<UserRepository>(),
        reportRepository: Get.find<ReportRepository>(),
        groupRepository: Get.find<GroupRepository>(),
      ),
    );

    Get.lazyPut(
      () => GetSuperAdminDashboardUseCase(
        userRepository: Get.find<UserRepository>(),
        groupRepository: Get.find<GroupRepository>(),
      ),
    );
  }
}
