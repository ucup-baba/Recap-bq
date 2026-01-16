import 'package:get/get.dart';

import '../../../../core/data/datasources/firestore_datasource.dart';
import '../../data/repositories/weekend_report_repository_impl.dart';
import '../../domain/usecases/submit_weekend_report_usecase.dart';
import '../../domain/usecases/validate_weekend_report_usecase.dart';

/// Dependency Injection Binding for Weekend Reports Feature
class WeekendReportsBinding extends Bindings {
  @override
  void dependencies() {
    // Register datasources (shared)
    if (!Get.isRegistered<FirestoreDataSource>()) {
      Get.lazyPut<FirestoreDataSource>(() => FirestoreDataSource());
    }

    // Register repository
    Get.lazyPut(
      () => WeekendReportRepositoryImpl(
        firestoreDataSource: Get.find<FirestoreDataSource>(),
      ),
    );

    // Register use cases
    Get.lazyPut(
      () => SubmitWeekendReportUseCase(Get.find<WeekendReportRepositoryImpl>()),
    );
    Get.lazyPut(
      () =>
          ValidateWeekendReportUseCase(Get.find<WeekendReportRepositoryImpl>()),
    );
  }
}
