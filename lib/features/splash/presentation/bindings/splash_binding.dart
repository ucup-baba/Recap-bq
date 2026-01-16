import 'package:get/get.dart';

import '../../../../features/auth/domain/usecases/get_current_user_usecase.dart';

/// Dependency Injection Binding for Splash Screen
/// Minimal logic - just checks auth state
class SplashBinding extends Bindings {
  @override
  void dependencies() {
    // Reuse auth use case for initialization check
    if (!Get.isRegistered<GetCurrentUserUseCase>()) {
      // Will be registered by AuthBinding
      // Splash just needs to check if user is logged in
    }
  }
}
