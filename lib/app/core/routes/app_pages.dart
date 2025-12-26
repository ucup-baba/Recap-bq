import 'package:get/get.dart';

import '../../modules/admin_dashboard/admin_dashboard_binding.dart';
import '../../modules/admin_dashboard/admin_dashboard_view.dart';
import '../../modules/auth/auth_binding.dart';
import '../../modules/auth/auth_view.dart';
import '../../modules/leaderboard/leaderboard_binding.dart';
import '../../modules/leaderboard/leaderboard_view.dart';
import '../../modules/leaderboard_ibadah/leaderboard_ibadah_binding.dart';
import '../../modules/leaderboard_ibadah/leaderboard_ibadah_view.dart';
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
import '../../modules/admin_ibadah/admin_ibadah_binding.dart';
import '../../modules/admin_ibadah/admin_ibadah_view.dart';
import '../../modules/kedisiplinan_dashboard/kedisiplinan_dashboard_binding.dart';
import '../../modules/kedisiplinan_dashboard/kedisiplinan_dashboard_view.dart';
import '../../modules/kedisiplinan_ibadah/kedisiplinan_ibadah_binding.dart';
import '../../modules/kedisiplinan_ibadah/kedisiplinan_ibadah_view.dart';
import '../../modules/manage_violation_rules/manage_violation_rules_binding.dart';
import '../../modules/manage_violation_rules/manage_violation_rules_view.dart';
import '../../modules/record_violation/record_violation_binding.dart';
import '../../modules/record_violation/record_violation_view.dart';
import '../../modules/violation_monitoring/violation_monitoring_binding.dart';
import '../../modules/violation_monitoring/violation_monitoring_view.dart';
import '../../modules/violation_detail/violation_detail_binding.dart';
import '../../modules/violation_detail/violation_detail_view.dart';
import '../../modules/super_admin_dashboard/super_admin_dashboard_binding.dart';
import '../../modules/super_admin_dashboard/super_admin_dashboard_view.dart';
import '../../modules/notification_settings/notification_settings_binding.dart';
import '../../modules/notification_settings/notification_settings_view.dart';
import '../../modules/manage_weekend_tasks/manage_weekend_tasks_binding.dart';
import '../../modules/manage_weekend_tasks/manage_weekend_tasks_view.dart';
import '../../modules/weekend_schedule/weekend_schedule_binding.dart';
import '../../modules/weekend_schedule/weekend_schedule_view.dart';
import '../../modules/weekend_report_input/weekend_report_input_binding.dart';
import '../../modules/weekend_report_input/weekend_report_input_view.dart';
import '../../modules/weekend_report_validation/weekend_report_validation_binding.dart';
import '../../modules/weekend_report_validation/weekend_report_validation_view.dart';

class AppRoutes {
  static const String splash = '/';
  static const String auth = '/auth';
  static const String adminDashboard = '/admin';
  static const String santriDashboard = '/santri';
  static const String reportInput = '/report-input';
  static const String reportValidation = '/report-validation';
  static const String leaderboard = '/leaderboard';
  static const String leaderboardIbadah = '/leaderboard-ibadah';
  static const String statistics = '/statistics';
  static const String manageTasks = '/manage-tasks';
  static const String manageMembers = '/manage-members';
  static const String adminIbadah = '/admin-ibadah';
  static const String kedisiplinanDashboard = '/kedisiplinan';
  static const String kedisiplinanIbadah = '/kedisiplinan-ibadah';
  static const String manageViolationRules = '/manage-violation-rules';
  static const String recordViolation = '/record-violation';
  static const String violationMonitoring = '/violation-monitoring';
  static const String violationDetail = '/violation-detail';
  static const String superAdminDashboard = '/super-admin';
  static const String notificationSettings = '/notification-settings';
  static const String manageWeekendTasks = '/manage-weekend-tasks';
  static const String weekendSchedule = '/weekend-schedule';
  static const String weekendReportInput = '/weekend-report-input';
  static const String weekendReportValidation = '/weekend-report-validation';
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
      name: AppRoutes.leaderboardIbadah,
      page: () => const LeaderboardIbadahView(),
      binding: LeaderboardIbadahBinding(),
    ),
    GetPage(
      name: AppRoutes.statistics,
      page: () => const StatisticsView(),
      binding: StatisticsBinding(),
    ),
    GetPage(
      name: AppRoutes.adminIbadah,
      page: () => const AdminIbadahView(),
      binding: AdminIbadahBinding(),
    ),
    GetPage(
      name: AppRoutes.kedisiplinanDashboard,
      page: () => const KedisiplinanDashboardView(),
      binding: KedisiplinanDashboardBinding(),
    ),
    GetPage(
      name: AppRoutes.kedisiplinanIbadah,
      page: () => const KedisiplinanIbadahView(),
      binding: KedisiplinanIbadahBinding(),
    ),
    GetPage(
      name: AppRoutes.manageViolationRules,
      page: () => const ManageViolationRulesView(),
      binding: ManageViolationRulesBinding(),
    ),
    GetPage(
      name: AppRoutes.recordViolation,
      page: () => const RecordViolationView(),
      binding: RecordViolationBinding(),
    ),
    GetPage(
      name: AppRoutes.violationMonitoring,
      page: () => const ViolationMonitoringView(),
      binding: ViolationMonitoringBinding(),
    ),
    GetPage(
      name: AppRoutes.violationDetail,
      page: () => const ViolationDetailView(),
      binding: ViolationDetailBinding(),
    ),
    GetPage(
      name: AppRoutes.superAdminDashboard,
      page: () => const SuperAdminDashboardView(),
      binding: SuperAdminDashboardBinding(),
    ),
    GetPage(
      name: AppRoutes.notificationSettings,
      page: () => const NotificationSettingsView(),
      binding: NotificationSettingsBinding(),
    ),
    GetPage(
      name: AppRoutes.manageWeekendTasks,
      page: () => const ManageWeekendTasksView(),
      binding: ManageWeekendTasksBinding(),
    ),
    GetPage(
      name: AppRoutes.weekendSchedule,
      page: () => const WeekendScheduleView(),
      binding: WeekendScheduleBinding(),
    ),
    GetPage(
      name: AppRoutes.weekendReportInput,
      page: () => const WeekendReportInputView(),
      binding: WeekendReportInputBinding(),
    ),
    GetPage(
      name: AppRoutes.weekendReportValidation,
      page: () => const WeekendReportValidationView(),
      binding: WeekendReportValidationBinding(),
    ),
  ];
}
