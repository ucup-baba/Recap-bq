import 'package:get/get.dart';

import '../../core/utils/logger.dart';
import '../../data/models/daily_ibadah_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firestore_service.dart';
import '../../data/services/ibadah_tracking_service.dart';

class StatisticsController extends GetxController {
  final _firestore = FirestoreService.instance;
  final _authService = AuthService.instance;
  final _ibadahService = IbadahTrackingService.instance;

  // Filter per kelompok (null = semua kelompok)
  final selectedKelompok = Rxn<int>();
  // Role user: true jika admin, false jika koordinator
  final isAdmin = false.obs;

  // Tab controller
  final selectedTabIndex = 0.obs; // 0: Individual, 1: Kelompok, 2: Amalan Yaumi

  // Amalan Yaumi statistics
  final RxBool isLoadingWeeklyIbadah = false.obs;
  final RxBool isLoadingMonthlyIbadah = false.obs;
  final RxList<DailyIbadahModel> weeklyIbadahData = <DailyIbadahModel>[].obs;
  final RxMap<DateTime, DailyIbadahModel> monthlyIbadahData =
      <DateTime, DailyIbadahModel>{}.obs;

  // Statistics
  final RxInt totalPushups = 0.obs;
  final RxDouble avgLevelPercentage = 0.0.obs;
  final RxMap<String, double> amalanPercentages = <String, double>{}.obs;
  final RxInt currentStreak = 0.obs;
  final RxInt bestStreak = 0.obs;
  final RxMap<String, double> sholatStatistics = <String, double>{}.obs;

  // Bulan yang sedang dilihat di kalender heatmap
  final Rx<DateTime> focusedDay = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    // Load user info dan set filter sesuai role
    _loadUserInfo();
  }

  @override
  void onReady() {
    super.onReady();
    // Load amalan yaumi data jika tab aktif
    if (selectedTabIndex.value == 2) {
      loadWeeklyIbadahData();
      loadMonthlyIbadahData(DateTime.now());
    }
  }

  void changeTab(int index) {
    selectedTabIndex.value = index;
    if (index == 2 && weeklyIbadahData.isEmpty) {
      // Load data jika belum pernah di-load
      loadWeeklyIbadahData();
      loadMonthlyIbadahData(DateTime.now());
    }
  }

  Future<void> _loadUserInfo() async {
    try {
      final firebaseUser = _authService.currentUser;
      if (firebaseUser == null) {
        Logger.warning('No current user');
        return;
      }

      final user = await _firestore.fetchUser(firebaseUser.uid);
      if (user != null) {
        // Cek role: admin bisa lihat semua, koordinator hanya kelompok sendiri
        isAdmin.value = user.role == 'admin';

        if (user.role == 'admin') {
          // Admin: default tampilkan semua kelompok (null)
          selectedKelompok.value = null;
          Logger.info('User is admin, showing all groups');
        } else if (user.kelompokId != null) {
          // Koordinator: force tampilkan kelompok sendiri
        selectedKelompok.value = user.kelompokId;
          Logger.info('User is koordinator kelompok ${user.kelompokId}');
      } else {
          Logger.warning('User has no kelompokId and is not admin');
        }
      }
    } catch (e) {
      Logger.error('Error loading user info', e);
    }
  }

  void setKelompokFilter(int? kelompokId) {
    // Koordinator tidak bisa ganti kelompok, hanya admin yang bisa
    if (!isAdmin.value) {
      Logger.info('Koordinator cannot change group filter');
      return;
    }
    selectedKelompok.value = kelompokId;
  }

  /// Stream kontribusi personal berdasarkan poin
  Stream<Map<String, int>> get contributionsStream {
    return selectedKelompok.stream.asyncExpand((kelompokId) {
      if (kelompokId != null) {
        // Filter per kelompok
        Logger.debug('Loading contributions for kelompok: $kelompokId');
        return _firestore.personalContributionForGroup(kelompokId).map((data) {
          Logger.debug(
            'Received ${data.length} members for kelompok $kelompokId',
          );
          return data;
        });
      } else {
        // Semua kelompok (gabungkan)
        Logger.debug('Loading contributions for all groups');
        return _firestore.personalContributionByGroup().map((grouped) {
          final Map<String, int> all = {};
          grouped.forEach((kelompokId, members) {
            members.forEach((name, points) {
              all[name] = (all[name] ?? 0) + points;
            });
          });
          Logger.debug('Combined ${all.length} members from all groups');
          return all;
        });
      }
    });
  }

  /// Stream untuk mendapatkan daftar kelompok (untuk dropdown filter)
  Stream<Map<int, Map<String, int>>> get groupedContributionsStream =>
      _firestore.personalContributionByGroup();

  // Amalan Yaumi methods
  Future<void> loadWeeklyIbadahData() async {
    try {
      isLoadingWeeklyIbadah.value = true;
      final data = await _ibadahService.getWeeklyIbadahData();
      weeklyIbadahData.value = data.reversed.toList();
      _calculateIbadahStatistics(weeklyIbadahData);
      _calculateIbadahStreak(weeklyIbadahData);
      _calculateIbadahSholatStatistics(weeklyIbadahData);
    } catch (e) {
      Logger.error('Error loading weekly ibadah data', e);
      Get.snackbar('Error', 'Gagal memuat data mingguan: $e');
    } finally {
      isLoadingWeeklyIbadah.value = false;
    }
  }

  Future<void> loadMonthlyIbadahData(DateTime month) async {
    try {
      isLoadingMonthlyIbadah.value = true;
      final data = await _ibadahService.getMonthlyIbadahData(month);
      monthlyIbadahData.value = data;
    } catch (e) {
      Logger.error('Error loading monthly ibadah data', e);
      Get.snackbar('Error', 'Gagal memuat data bulanan: $e');
    } finally {
      isLoadingMonthlyIbadah.value = false;
    }
  }

  void onMonthChanged(DateTime newMonth) {
    focusedDay.value = newMonth;
    loadMonthlyIbadahData(newMonth);
  }

  void _calculateIbadahStatistics(List<DailyIbadahModel> data) {
    if (data.isEmpty) {
      totalPushups.value = 0;
      avgLevelPercentage.value = 0.0;
      amalanPercentages.value = {};
      return;
    }

    int totalPushupCount = 0;
    double totalPercentageSum = 0;

    Map<String, int> amalanCounts = {
      'Tahajud': 0,
      'Dhuha': 0,
      'Al-Mulk (67)': 0,
      'Al-Waqi\'ah (56)': 0,
      'Al-Kahfi / Yasin': 0,
    };

    for (var dayData in data) {
      totalPushupCount += dayData.pushup ?? 0;
      totalPercentageSum += dayData.calculateLevelPercentage();

      if (dayData.tahajud == true) {
        amalanCounts['Tahajud'] = (amalanCounts['Tahajud'] ?? 0) + 1;
      }
      if (dayData.sholatDhuha == true) {
        amalanCounts['Dhuha'] = (amalanCounts['Dhuha'] ?? 0) + 1;
      }
      if (dayData.alMulk == true) {
        amalanCounts['Al-Mulk (67)'] = (amalanCounts['Al-Mulk (67)'] ?? 0) + 1;
      }
      if (dayData.surah56 == true) {
        amalanCounts['Al-Waqi\'ah (56)'] = (amalanCounts['Al-Waqi\'ah (56)'] ?? 0) + 1;
      }
      if (dayData.alkahfiOrYasin == true) {
        amalanCounts['Al-Kahfi / Yasin'] = (amalanCounts['Al-Kahfi / Yasin'] ?? 0) + 1;
      }
    }

    totalPushups.value = totalPushupCount;
    avgLevelPercentage.value = (totalPercentageSum / data.length) * 100;

    amalanPercentages.value = {
      'Tahajud': (amalanCounts['Tahajud'] ?? 0) / data.length,
      'Dhuha': (amalanCounts['Dhuha'] ?? 0) / data.length,
      'Al-Mulk (67)': (amalanCounts['Al-Mulk (67)'] ?? 0) / data.length,
      'Al-Waqi\'ah (56)': (amalanCounts['Al-Waqi\'ah (56)'] ?? 0) / data.length,
      'Al-Kahfi / Yasin': (amalanCounts['Al-Kahfi / Yasin'] ?? 0) / data.length,
    };
  }

  void _calculateIbadahStreak(List<DailyIbadahModel> data) {
    if (data.isEmpty) {
      currentStreak.value = 0;
      bestStreak.value = 0;
      return;
    }

    // Sort by date descending (newest first)
    final sortedData = List<DailyIbadahModel>.from(data)..sort((a, b) {
      final dateA = DateTime.parse(a.date);
      final dateB = DateTime.parse(b.date);
      return dateB.compareTo(dateA);
    });

    int current = 0;
    int best = 0;
    int tempStreak = 0;

    // Calculate current streak (from today backwards)
    final today = DateTime.now();
    final todayNormalized = DateTime.utc(today.year, today.month, today.day);

    for (int i = 0; i < sortedData.length; i++) {
      final dayData = sortedData[i];
      final dateParsed = DateTime.parse(dayData.date);
      final dayNormalized = DateTime.utc(dateParsed.year, dateParsed.month, dateParsed.day);

      // Check if this is a consecutive day
      final expectedDate = todayNormalized.subtract(Duration(days: i));

      if (dayNormalized == expectedDate && dayData.calculateLevelPercentage() > 0) {
        current++;
      } else {
        break; // Streak broken
      }
    }

    // Calculate best streak (any consecutive days)
    for (var dayData in sortedData.reversed) {
      if (dayData.calculateLevelPercentage() > 0) {
        tempStreak++;
        if (tempStreak > best) {
          best = tempStreak;
        }
      } else {
        tempStreak = 0;
      }
    }

    currentStreak.value = current;
    bestStreak.value = best > current ? best : current;
  }

  void _calculateIbadahSholatStatistics(List<DailyIbadahModel> data) {
    if (data.isEmpty) {
      sholatStatistics.value = {'jamaah': 0.0, 'qobliyah': 0.0, 'badiyah': 0.0};
      return;
    }

    int totalJamaah = 0;
    int totalQobliyah = 0;
    int totalBadiyah = 0;

    // Maximum possible per day
    const int maxJamaahPerDay = 5; // Subuh, Dzuhur, Ashar, Maghrib, Isya
    const int maxQobliyahPerDay = 1; // Subuh Qobliyah
    const int maxBadiyahPerDay = 3; // Dzuhur, Maghrib, Isya Badiyah

    for (var dayData in data) {
      // Count Jamaah
      if (dayData.subuhJamaah == true) {
        totalJamaah++;
      }
      if (dayData.dzuhurJamaah == true) {
        totalJamaah++;
      }
      if (dayData.asharJamaah == true) {
        totalJamaah++;
      }
      if (dayData.maghribJamaah == true) {
        totalJamaah++;
      }
      if (dayData.isyaJamaah == true) {
        totalJamaah++;
      }

      // Count Qobliyah
      if (dayData.subuhQobliyah == true) {
        totalQobliyah++;
      }

      // Count Badiyah
      if (dayData.dzuhurBadiyah == true) {
        totalBadiyah++;
      }
      if (dayData.maghribBadiyah == true) {
        totalBadiyah++;
      }
      if (dayData.isyaBadiyah == true) {
        totalBadiyah++;
      }
    }

    final totalDays = data.length;

    sholatStatistics.value = {
      'jamaah': totalJamaah / (totalDays * maxJamaahPerDay),
      'qobliyah': totalQobliyah / (totalDays * maxQobliyahPerDay),
      'badiyah': totalBadiyah / (totalDays * maxBadiyahPerDay),
    };
  }
}
