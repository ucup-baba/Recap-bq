import 'package:get/get.dart';
import '../../modules/auth/auth_view.dart';
import '../../modules/auth/auth_binding.dart';
import '../../modules/auth/pending_approval_view.dart';
import '../../modules/dashboard/dashboard_view.dart';
import '../../modules/dashboard/dashboard_binding.dart';
import '../../modules/role_management/role_list_view.dart';
import '../../modules/role_management/role_binding.dart';
import '../../modules/user_management/user_management_view.dart';
import '../../modules/user_management/user_management_binding.dart';
import '../../modules/user_dashboard/user_dashboard_view.dart';
import '../../modules/user_dashboard/user_dashboard_binding.dart';

/// App Routes
abstract class AppRoutes {
  static const splash = '/';
  static const auth = '/auth';
  static const dashboard = '/dashboard';
  static const roles = '/roles';
  static const users = '/users';
  static const userDashboard = '/user-dashboard';
  static const pendingApproval = '/pending-approval';
}

/// App Pages Configuration
class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.auth,
      page: () => const AuthView(),
      binding: AuthBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardView(),
      binding: DashboardBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.roles,
      page: () => const RoleListView(),
      binding: RoleBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.users,
      page: () => const UserManagementView(),
      binding: UserManagementBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.userDashboard,
      page: () => const UserDashboardView(),
      binding: UserDashboardBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.pendingApproval,
      page: () => const PendingApprovalView(),
      transition: Transition.fadeIn,
    ),
  ];
}
