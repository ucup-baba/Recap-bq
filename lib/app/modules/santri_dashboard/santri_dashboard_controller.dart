import 'dart:async';

import 'package:get/get.dart';

import '../../core/routes/app_pages.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/daily_report_model.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firestore_service.dart';
import '../../data/services/rotation_service.dart';

class SantriDashboardController extends GetxController {
  final _authService = AuthService.instance;
  final _firestore = FirestoreService.instance;
  final _rotation = RotationService();

  final user = Rxn<UserModel>();
  final areaTugas = ''.obs;
  final poin = 0.obs;
  final streak = 0.obs;
  final personalPoints = 0.obs;
  final reportStatus = ''.obs;
  final _hasFetchedOnce = false.obs;
  final kelompokIdStr = '-'.obs; // String untuk tampilan kelompok

  StreamSubscription<UserModel?>? _userSubscription;
  StreamSubscription<List<DailyReportModel>>? _reportSubscription;

  @override
  void onInit() {
    super.onInit();
    // Cek apakah ada status dari navigasi (setelah submit laporan)
    final args = Get.arguments;
    Logger.info('Dashboard onInit - arguments: $args');
    if (args != null && args is Map<String, dynamic>) {
      final statusFromArgs = args['reportStatus'] as String?;
      if (statusFromArgs != null) {
        reportStatus.value = statusFromArgs;
        Logger.info(
          'Dashboard received reportStatus from navigation: ${reportStatus.value}',
        );
      } else {
        Logger.info('Dashboard onInit - no reportStatus in arguments');
      }
    } else {
      Logger.info('Dashboard onInit - arguments is null or not a Map');
    }
    _loadUser();
  }

  @override
  void onClose() {
    _userSubscription?.cancel();
    _reportSubscription?.cancel();
    super.onClose();
  }

  Future<void> _loadUser() async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser == null) {
      Get.offAllNamed('/auth');
      return;
    }
    _userSubscription?.cancel();
    _userSubscription = _firestore.watchUser(firebaseUser.uid).listen((
      profile,
    ) {
      if (profile == null) return;
      user.value = profile;
      poin.value = profile.totalPoin;
      streak.value = profile.currentStreak;
      personalPoints.value = profile.personalPoints;
      kelompokIdStr.value = profile.kelompokId?.toString() ?? '-';
      if (profile.kelompokId != null) {
        areaTugas.value = _rotation.getAreaForGroup(
          profile.kelompokId!,
          DateTime.now(),
        );
        _watchTodayReport(profile.kelompokId!);
      }
    });
  }

  String get today => AppDateUtils.formatDate(DateTime.now());

  void _watchTodayReport(int kelompokId) {
    _reportSubscription?.cancel();
    _hasFetchedOnce.value = false;

    // Selalu fetch sekali untuk memastikan data terbaru dari Firestore
    // Bahkan jika status sudah di-set dari navigation arguments
    _fetchTodayOnce(kelompokId);

    // Tetap dengarkan stream untuk update real-time (verified/rejected/reset oleh admin)
    _reportSubscription = _firestore
        .reportsByGroupAndDate(kelompokId, today)
        .listen(
          (reports) {
            _hasFetchedOnce.value = true;
            if (reports.isEmpty) {
              // Setelah reset, laporan dihapus, jadi status harus di-clear
              reportStatus.value = '';
              Logger.info(
                'No report found (stream): kelompokId=$kelompokId, date=$today',
              );
            } else {
              final status = reports.first.status;
              reportStatus.value = status;
              Logger.info(
                'Today report found (stream): status=$status, kelompokId=$kelompokId, date=$today',
              );
            }
          },
          onError: (error) {
            Logger.error('Error watching today report', error);
            // Clear status jika error
            reportStatus.value = '';
          },
        );
  }

  /// Fetch sekali dokumen harian by ID untuk menampilkan status segera setelah submit.
  Future<void> _fetchTodayOnce(int kelompokId) async {
    try {
      final reportId = '$kelompokId-$today';
      final doc = await FirestoreService.instance.getDailyReportById(reportId);
      _hasFetchedOnce.value = true;
      if (doc == null) {
        // Dokumen tidak ada, clear status
        reportStatus.value = '';
        Logger.info('Today report not found (fetch once): reportId=$reportId');
        return;
      }
      // Update status dengan data terbaru dari Firestore
      reportStatus.value = doc.status;
      Logger.info(
        'Today report found (fetch once): status=${doc.status}, reportId=$reportId',
      );
    } catch (e) {
      Logger.error('Error fetch today report once', e);
      _hasFetchedOnce.value = true;
      // Jika error dan status belum di-set, set ke kosong
      // Tapi jika sudah ada status dari navigation, pertahankan
      if (reportStatus.value.isEmpty) {
        reportStatus.value = '';
      }
    }
  }

  Future<void> logout() async {
    try {
      await _authService.signOut();
      Get.offAllNamed(AppRoutes.auth);
      Logger.info('User logged out successfully');
    } catch (e) {
      Logger.error('Error logging out', e);
      SnackbarHelper.showError('Gagal logout');
    }
  }
}
