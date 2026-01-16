import 'package:get/get.dart';

import '../../../core/data/repositories/report_repository_impl.dart';
import '../../../core/domain/repositories/report_repository.dart';
import '../../domain/usecases/submit_daily_report_usecase.dart';

/// Dependency Injection Binding for Report Input Feature
class ReportInputBinding extends Bindings {
  @override
  void dependencies() {
    // Register shared repository if not already registered
    if (!Get.isRegistered<ReportRepository>()) {
      Get.lazyPut<ReportRepository>(() => Get.find<ReportRepositoryImpl>());
    }

    // Register use case
    Get.lazyPut(() => SubmitDailyReportUseCase(Get.find<ReportRepository>()));
  }
}
