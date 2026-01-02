import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/app_pages.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/motivation_dialog.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/daily_ibadah_model.dart';
import '../../data/models/daily_report_model.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firestore_service.dart';
import '../../data/services/ibadah_tracking_service.dart';
import '../../data/services/rotation_service.dart';
import '../../core/interfaces/ibadah_controller_interface.dart';

class SantriDashboardController extends GetxController
    implements IbadahControllerInterface {
  final _authService = AuthService.instance;
  final _firestore = FirestoreService.instance;
  final _rotationService = RotationService();
  final _ibadahService = IbadahTrackingService.instance;

  // Tab navigation
  final currentTabIndex = 0.obs;

  void changeTab(int index) {
    Logger.info('Santri: Changing tab from ${currentTabIndex.value} to $index');
    currentTabIndex.value = index;
  }

  // User & Group Data
  final userProfile = Rxn<Map<String, dynamic>>();
  final areaTugas = ''.obs;
  final poin = 0.obs;
  final streak = 0.obs;
  final todayDate = ''.obs; // For display: "Senin, 12 Agustus 2024"
  final welcomeMessage = ''.obs;
  final nextShift = ''.obs;

  // Logic properties
  final reportStatus = ''.obs;
  final _hasFetchedOnce = false.obs;
  final kelompokIdStr = '-'.obs;

  StreamSubscription? _userSubscription;
  StreamSubscription? _reportSubscription;
  StreamSubscription? _weekendReportSubscription;

  // Ibadah Data
  final _todayIbadah = Rxn<DailyIbadahModel>();
  final isLoading = false.obs;
  final showPushupMotivation = false.obs;
  final selectedDate = DateTime.now().obs;
  final pushupMotivation = ''.obs;

  // Weekend
  final weekendSchedule = Rxn<Map<String, dynamic>>();
  final weekendSlot = ''.obs;

  // Getters
  String get today => AppDateUtils.formatDate(DateTime.now());
  bool get isFriday => selectedDate.value.weekday == DateTime.friday;

  @override
  DailyIbadahModel? todayIbadah() => _todayIbadah.value;

  // Interface implementations
  @override
  Future<void> loadTodayIbadah() async {
    try {
      final ibadah = await _ibadahService.getTodayIbadah();
      _todayIbadah.value = ibadah;
      if (ibadah != null) {
        _updatePushupMotivation(ibadah.pushup ?? 0);
      }
    } catch (e) {
      Logger.error('Error loading today ibadah', e);
    }
  }

  @override
  void showAmalanMotivation() {
    const motivations = [
      {
        'title': 'Malas Tahajud?',
        'body': 'Tahajud adalah waktu terbaik untuk curhat dengan Allah.',
        'emoji': '🌙',
        'button': 'Insya Allah! 🌙',
      },
      {
        'title': 'Ragu Sholat Dhuha?',
        'body':
            'Cukup 2 rakaat sholat Dhuha sebagai sedekah untuk seluruh tubuh.',
        'emoji': '☀️',
        'button': 'Semangat! ☀️',
      },
      {
        'title': 'Berat Baca Al-Mulk?',
        'body': 'Hanya 5 menit, tapi bisa menyelamatkan dari siksa kubur.',
        'emoji': '📖',
        'button': 'Bismillah! 📖',
      },
    ];
    final randomMotivation = motivations[Random().nextInt(motivations.length)];
    MotivationDialog.show(
      title: randomMotivation['title']!,
      body: randomMotivation['body']!,
      emoji: randomMotivation['emoji']!,
      buttonText: randomMotivation['button']!,
    );
  }

  @override
  void showSholatMotivation() {
    const motivations = [
      {
        'title': 'Kenapa Harus Sholat?',
        'body':
            'Karena sholat adalah tiang agama dan koneksi utama kita dengan Allah.',
        'emoji': '🕌',
        'button': 'Siap! 💪',
      },
      {
        'title': 'Merasa Berat Sholat?',
        'body':
            'Ingat, sholat itu hanya beberapa menit. Prioritaskan yang abadi.',
        'emoji': '🤲',
        'button': 'Bismillah! 🤲',
      },
    ];
    final randomMotivation = motivations[Random().nextInt(motivations.length)];
    MotivationDialog.show(
      title: randomMotivation['title']!,
      body: randomMotivation['body']!,
      emoji: randomMotivation['emoji']!,
      buttonText: randomMotivation['button']!,
    );
  }

  @override
  Future<void> updateIbadah(DailyIbadahModel updatedIbadah) async {
    try {
      _todayIbadah.value = updatedIbadah;
      _updatePushupMotivation(updatedIbadah.pushup ?? 0);
      await loadTodayIbadah();
    } catch (e) {
      Logger.error('Error updating ibadah', e);
    }
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null && args is Map<String, dynamic>) {
      final statusFromArgs = args['reportStatus'] as String?;
      if (statusFromArgs != null) {
        reportStatus.value = statusFromArgs;
      }
    }
    _loadUser();
    todayDate.value = AppDateUtils.formatDate(DateTime.now());
  }

  @override
  void onClose() {
    _userSubscription?.cancel();
    _reportSubscription?.cancel();
    _weekendReportSubscription?.cancel();
    super.onClose();
  }

  Future<void> _loadUser() async {
    isLoading.value = true;
    try {
      final user = _authService.currentUser;
      if (user == null) {
        Get.offAllNamed(AppRoutes.auth);
        return;
      }

      _userSubscription?.cancel();
      _userSubscription = _firestore.watchUser(user.uid).listen((userData) {
        if (userData != null) {
          userProfile.value = userData.toMap();
          poin.value = userData.totalPoin;
          streak.value = userData.currentStreak;
          kelompokIdStr.value = userData.kelompokId?.toString() ?? '-';

          final hour = DateTime.now().hour;
          if (hour < 10)
            welcomeMessage.value = 'Selamat Pagi,';
          else if (hour < 15)
            welcomeMessage.value = 'Selamat Siang,';
          else if (hour < 18)
            welcomeMessage.value = 'Selamat Sore,';
          else
            welcomeMessage.value = 'Selamat Malam,';

          if (userData.kelompokId != null) {
            final kelompokId = userData.kelompokId!;
            areaTugas.value = _rotationService.getAreaForGroup(
              kelompokId,
              DateTime.now(),
            );

            _watchTodayReport(kelompokId);
            loadTodayIbadah();
          }
        }
      });
    } catch (e) {
      Logger.error('Error loading santri dashboard data', e);
    } finally {
      isLoading.value = false;
    }
  }

  void _watchTodayReport(int kelompokId) {
    _reportSubscription?.cancel();
    _weekendReportSubscription?.cancel();
    _hasFetchedOnce.value = false;

    final now = DateTime.now();
    final isWeekend =
        now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;

    if (isWeekend) {
      _fetchWeekendReportOnce(kelompokId, now);
      _weekendReportSubscription = _firestore
          .watchWeekendReportsForDate(now)
          .listen(
            (reports) {
              _hasFetchedOnce.value = true;
              final kelompokReports = reports
                  .where((r) => r['kelompokId'] == kelompokId)
                  .toList();
              if (kelompokReports.isEmpty) {
                reportStatus.value = '';
              } else {
                reportStatus.value =
                    kelompokReports.first['status'] as String? ?? 'draft';
              }
            },
            onError: (error) =>
                Logger.error('Error watching weekend report', error),
          );
    } else {
      _fetchTodayOnce(kelompokId);
      _reportSubscription = _firestore
          .reportsByGroupAndDate(kelompokId, today)
          .listen(
            (reports) {
              _hasFetchedOnce.value = true;
              if (reports.isEmpty) {
                reportStatus.value = '';
              } else {
                reportStatus.value = reports.first.status;
              }
            },
            onError: (error) =>
                Logger.error('Error watching today report', error),
          );
    }
  }

  Future<void> _fetchWeekendReportOnce(int kelompokId, DateTime date) async {
    try {
      final reports = await _firestore.getWeekendReportsForKelompok(
        date,
        kelompokId,
      );
      _hasFetchedOnce.value = true;
      if (reports.isEmpty) {
        reportStatus.value = '';
        return;
      }
      reportStatus.value = reports.first['status'] as String? ?? 'draft';
    } catch (e) {
      Logger.error('Error fetch weekend report once', e);
      _hasFetchedOnce.value = true;
      if (reportStatus.value.isEmpty) reportStatus.value = '';
    }
  }

  Future<void> _fetchTodayOnce(int kelompokId) async {
    try {
      final reportId = '$kelompokId-$today';
      final doc = await FirestoreService.instance.getDailyReportById(reportId);
      _hasFetchedOnce.value = true;
      if (doc == null) {
        reportStatus.value = '';
        return;
      }
      reportStatus.value = doc.status;
    } catch (e) {
      Logger.error('Error fetch today report once', e);
      _hasFetchedOnce.value = true;
      if (reportStatus.value.isEmpty) reportStatus.value = '';
    }
  }

  Future<void> logout() async {
    try {
      await _authService.signOut();
      Get.offAllNamed(AppRoutes.auth);
    } catch (e) {
      Logger.error('Error logging out', e);
      SnackbarHelper.showError('Gagal logout');
    }
  }

  void _updatePushupMotivation(int count) {
    if (count == 0)
      pushupMotivation.value = 'Omong kosong... Target 25x!';
    else if (count == 25)
      pushupMotivation.value = 'Ehem, baru sama dengan anak-anak...';
    else if (count > 25 && count < 40)
      pushupMotivation.value = 'Lumayan, otot mulai terbentuk.';
    else if (count >= 40)
      pushupMotivation.value = 'Bagus! Jaga konsistensinya.';
  }
}
