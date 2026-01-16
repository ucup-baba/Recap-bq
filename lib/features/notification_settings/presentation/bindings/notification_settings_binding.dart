import 'package:get/get.dart';

import '../../domain/usecases/manage_notification_settings_usecase.dart';

/// Dependency Injection Binding for Notification Settings Feature
class NotificationSettingsBinding extends Bindings {
  @override
  void dependencies() {
    // Register use case
    Get.lazyPut(() => ManageNotificationSettingsUseCase());
  }
}
