import 'package:get/get.dart';

import '../../modules/admin_dashboard/admin_dashboard_binding.dart';
import '../../modules/admin_dashboard/admin_dashboard_view.dart';
import '../../modules/auth/auth_binding.dart';
import '../../modules/auth/auth_view.dart';
import '../../modules/leaderboard/leaderboard_binding.dart';
import '../../modules/leaderboard/leaderboard_view.dart';
import '../../modules/manage_members/manage_members_binding.dart';
import '../../modules/manage_members/manage_members_view.dart';
import '../../modules/manage_tasks/manage_tasks_binding.dart';
import '../../modules/manage_tasks/manage_tasks_view.dart';
import '../../modules/report_input/report_input_binding.dart';
import '../../modules/report_input/report_input_view.dart';
import '../../modules/report_validation/report_validation_binding.dart';
import '../../modules/report_validation/report_validation_view.dart';
import '../../modules/santri_dashboard/santri_dashboard_binding.dart';
import '../../modules/santri_dashboard/santri_dashboard_view.dart';
import '../../modules/splash/splash_binding.dart';
import '../../modules/splash/splash_view.dart';
import '../../modules/statistics/statistics_binding.dart';
import '../../modules/statistics/statistics_view.dart';

class AppRoutes {
  static const String splash = '/';
  static const String auth = '/auth';
  static const String adminDashboard = '/admin';
  static const String santriDashboard = '/santri';
  static const String reportInput = '/report-input';
  static const String reportValidation = '/report-validation';
  static const String leaderboard = '/leaderboard';
  static const String statistics = '/statistics';
  static const String manageTasks = '/manage-tasks';
  static const String manageMembers = '/manage-members';
}

class AppPages {
  static final routes = <GetPage>[
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.auth,
      page: () => const AuthView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.adminDashboard,
      page: () => const AdminDashboardView(),
      binding: AdminDashboardBinding(),
    ),
    GetPage(
      name: AppRoutes.santriDashboard,
      page: () => const SantriDashboardView(),
      binding: SantriDashboardBinding(),
    ),
    GetPage(
      name: AppRoutes.reportInput,
      page: () => const ReportInputView(),
      binding: ReportInputBinding(),
    ),
    GetPage(
      name: AppRoutes.reportValidation,
      page: () => const ReportValidationView(),
      binding: ReportValidationBinding(),
    ),
    GetPage(
      name: AppRoutes.manageTasks,
      page: () => const ManageTasksView(),
      binding: ManageTasksBinding(),
    ),
    GetPage(
      name: AppRoutes.manageMembers,
      page: () => const ManageMembersView(),
      binding: ManageMembersBinding(),
    ),
    GetPage(
      name: AppRoutes.leaderboard,
      page: () => const LeaderboardView(),
      binding: LeaderboardBinding(),
    ),
    GetPage(
      name: AppRoutes.statistics,
      page: () => const StatisticsView(),
      binding: StatisticsBinding(),
    ),
  ];
}
