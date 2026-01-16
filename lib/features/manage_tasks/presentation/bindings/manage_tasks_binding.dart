import 'package:get/get.dart';

import '../../domain/usecases/manage_daily_tasks_usecase.dart';

/// Dependency Injection Binding for Manage Tasks Feature
class ManageTasksBinding extends Bindings {
  @override
  void dependencies() {
    // Register use case
    Get.lazyPut(() => ManageDailyTasksUseCase());
  }
}
