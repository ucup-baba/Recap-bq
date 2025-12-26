import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/app_pages.dart';
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
  final _rotation = RotationService();
  final _ibadahService = IbadahTrackingService.instance;

  final user = Rxn<UserModel>();
  final areaTugas = ''.obs;
  final poin = 0.obs;
  final streak = 0.obs;
  final personalPoints = 0.obs;
  final reportStatus = ''.obs;
  final _hasFetchedOnce = false.obs;
  final kelompokIdStr = '-'.obs; // String untuk tampilan kelompok

  // Ibadah tracking
  final _todayIbadah = Rxn<DailyIbadahModel>();
  final selectedDate = DateTime.now().obs;
  @override
  final pushupMotivation = ''.obs;

  // Getter untuk observable (untuk reactive UI)
  Rxn<DailyIbadahModel> get todayIbadahRx => _todayIbadah;

  // Method untuk compatibility dengan widget cards
  @override
  DailyIbadahModel? todayIbadah() => _todayIbadah.value;

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
    _loadTodayIbadah();
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
    _userSubscription = _firestore
        .watchUser(firebaseUser.uid)
        .listen(
          (profile) {
            if (profile == null) {
              Logger.warning('User profile is null in watchUser stream');
              return;
            }
            Logger.info(
              'User profile loaded: uid=${profile.uid}, kelompokId=${profile.kelompokId}, role=${profile.role}',
            );
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
              Logger.info(
                'Area tugas set: ${areaTugas.value} for kelompok ${profile.kelompokId}',
              );
              _watchTodayReport(profile.kelompokId!);
            } else {
              Logger.warning('User profile has no kelompokId');
              areaTugas.value = '';
            }
          },
          onError: (error) {
            Logger.error('Error in watchUser stream', error);
          },
        );
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

  // Ibadah tracking methods
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

  Future<void> _loadTodayIbadah() async => loadTodayIbadah();

  @override
  Future<void> updateIbadah(DailyIbadahModel updatedIbadah) async {
    try {
      _todayIbadah.value = updatedIbadah;
      _updatePushupMotivation(updatedIbadah.pushup ?? 0);
      // Data sudah disimpan via service di widget cards
      await _loadTodayIbadah(); // Reload untuk memastikan sync
    } catch (e) {
      Logger.error('Error updating ibadah', e);
    }
  }

  void _updatePushupMotivation(int count) {
    if (count == 0) {
      pushupMotivation.value = 'Omong kosong... Target 25x!';
    } else if (count == 25) {
      pushupMotivation.value = 'Ehem, baru sama dengan anak-anak...';
    } else if (count > 25 && count < 40) {
      pushupMotivation.value = 'Lumayan, otot mulai terbentuk.';
    } else if (count >= 40) {
      pushupMotivation.value = 'Bagus! Jaga konsistensinya.';
    }
  }

  @override
  void showSholatMotivation() {
    const motivations = [
      {
        'title': 'Kenapa Harus Sholat?',
        'body':
            'Karena sholat adalah tiang agama dan koneksi utama kita dengan Allah. Ini adalah hal pertama yang akan dihisab.',
      },
      {
        'title': 'Merasa Berat Sholat?',
        'body':
            'Ingat, sholat itu hanya beberapa menit. Waktu yang kita habiskan untuk media sosial jauh lebih lama. Prioritaskan yang abadi.',
      },
    ];
    final randomMotivation = motivations[Random().nextInt(motivations.length)];
    Get.defaultDialog(
      title: randomMotivation['title']!,
      middleText: randomMotivation['body']!,
      backgroundColor: Get.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      titleStyle: TextStyle(
        fontWeight: FontWeight.bold,
        color: Get.isDarkMode ? Colors.white : Colors.black,
      ),
      middleTextStyle: TextStyle(
        color: Get.isDarkMode ? Colors.white70 : Colors.black87,
      ),
      radius: 16,
      textConfirm: 'Siap!',
      confirmTextColor: Colors.white,
      buttonColor: Colors.deepPurple.shade600,
    );
  }

  @override
  void showAmalanMotivation() {
    const motivations = [
      {
        'title': 'Malas Tahajud?',
        'body':
            'Tahajud adalah waktu terbaik untuk curhat dengan Allah. Saat orang lain tidur, doa Anda menembus langit.',
      },
      {
        'title': 'Ragu Sholat Dhuha?',
        'body':
            'Cukup 2 rakaat sholat Dhuha sebagai sedekah untuk seluruh sendi di tubuh Anda. Pembuka pintu rezeki!',
      },
      {
        'title': 'Berat Baca Al-Mulk (S.67)?',
        'body':
            'Hanya 30 ayat, kurang dari 5 menit. Tapi bisa menyelamatkan Anda dari siksa kubur. Sangat setimpal!',
      },
      {
        'title': 'Lupa Al-Waqi\'ah (S.56)?',
        'body':
            'Surat ini dikenal sebagai surat "kecukupan". Membacanya setiap malam menjauhkan kita dari kefakiran.',
      },
      {
        'title': 'Melewatkan Yasin (S.36)?',
        'body':
            'Yasin adalah jantung Al-Quran. Membacanya di pagi hari akan mempermudah semua urusan Anda hari itu.',
      },
    ];
    final randomMotivation = motivations[Random().nextInt(motivations.length)];
    Get.defaultDialog(
      title: randomMotivation['title']!,
      middleText: randomMotivation['body']!,
      backgroundColor: Get.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      titleStyle: TextStyle(
        fontWeight: FontWeight.bold,
        color: Get.isDarkMode ? Colors.white : Colors.black,
      ),
      middleTextStyle: TextStyle(
        color: Get.isDarkMode ? Colors.white70 : Colors.black87,
      ),
      radius: 16,
      textConfirm: 'Oke!',
      confirmTextColor: Colors.white,
      buttonColor: Colors.deepPurple.shade600,
    );
  }

  bool get isFriday => selectedDate.value.weekday == DateTime.friday;
}
