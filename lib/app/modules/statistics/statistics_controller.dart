import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../core/utils/logger.dart';
import '../../data/models/daily_ibadah_model.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firestore_service.dart';
import '../../data/services/ibadah_tracking_service.dart';
import '../../data/services/running_service.dart';

class StatisticsController extends GetxController {
  final _firestore = FirestoreService.instance;
  final _authService = AuthService.instance;
  final _ibadahService = IbadahTrackingService.instance;
  final _runningService = RunningService.instance;

  // Filter per kelompok (null = semua kelompok)
  final selectedKelompok = Rxn<int>();
  // Role user: true jika admin, false jika koordinator
  final isAdmin = false.obs;

  // Multi-user selection
  final RxList<UserModel> availableUsers = <UserModel>[].obs;
  final Rxn<UserModel> selectedUser = Rxn<UserModel>();

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

  // Running stats
  final RxInt monthlyRunningDays = 0.obs;
  final RxInt runningStreak = 0.obs;

  // User ranking
  final RxInt userRank = 0.obs;
  final RxInt totalUsersInGroup = 0.obs;

  // Bulan yang sedang dilihat di kalender heatmap
  final Rx<DateTime> focusedDay = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize locale for table_calendar
    _initializeLocale();
    // Load user info dan set filter sesuai role
    _loadUserInfo();
  }

  Future<void> _initializeLocale() async {
    try {
      await initializeDateFormatting('id_ID', null);
    } catch (e) {
      Logger.warning('Error initializing locale: $e');
    }
  }

  @override
  void onReady() {
    super.onReady();
    // Load amalan yaumi data saat halaman dibuka (weekly only)
    loadWeeklyIbadahData().then((_) => loadUserRanking());
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
        // Only super_admin can view all users' ibadah statistics
        // Admin is treated same as koordinator (can only see own data)
        isAdmin.value = user.role == 'super_admin';

        if (user.role == 'super_admin') {
          // Super Admin: default tampilkan semua kelompok (null)
          selectedKelompok.value = null;
          Logger.info('User is super_admin, showing all groups');
          // Load all users for filter
          loadAvailableUsers();
        } else if (user.kelompokId != null) {
          // Admin/Koordinator: force tampilkan kelompok sendiri
          selectedKelompok.value = user.kelompokId;
          Logger.info('User is ${user.role} kelompok ${user.kelompokId}');
          // Load users in group
          loadAvailableUsers();
        } else {
          Logger.warning('User has no kelompokId and is not super_admin');
        }

        // Set default selected user to self
        selectedUser.value = user;
      }
    } catch (e) {
      Logger.error('Error loading user info', e);
    }
  }

  void setKelompokFilter(int? kelompokId) {
    // Only super_admin can change group filter
    if (!isAdmin.value) {
      Logger.info('Non-super_admin cannot change group filter');
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

  Future<void> loadAvailableUsers() async {
    try {
      final currentUser = await _firestore.fetchUser(
        _authService.currentUser?.uid ?? '',
      );
      if (currentUser == null) return;

      List<UserModel> users = [];
      if (isAdmin.value) {
        // Admin: load all users but filter for leaderboard-relevant accounts
        // (Super Admin, Admin, Kedisiplinan, Ketua Kelompok)
        final all = await _firestore.getAllUsers();
        users = all.where((user) {
          final role = user.role;
          final name = user.displayName.toLowerCase();

          // Always include these roles
          if (role == 'admin' ||
              role == 'super_admin' ||
              role == 'kedisplinan') {
            return true;
          }

          // For koordinator/others, only include if "Ketua"
          if (name.contains('ketua') || user.uid.startsWith('ketuakel')) {
            return true;
          }

          return false;
        }).toList();
      } else {
        // Koordinator: load users in group
        // Note: FirestoreService might not have getUsersByGroup, checking...
        // If not, we can filter getAllUsers or add method.
        // Assuming we can use getAllUsers and filter for now as it's safer than adding new service method blindly
        // But wait, getAllUsers might be heavy. Let's check if we can optimize.
        // Actually, let's just fetch all for now or filter if possible.
        // Better: use Existing method or fetch all and filter.
        final all = await _firestore.getAllUsers();
        users = all
            .where((u) => u.kelompokId == currentUser.kelompokId)
            .toList();
      }

      // Sort: Admin/Super Admin first, then Alpha
      users.sort((a, b) {
        if (a.role.contains('admin') && !b.role.contains('admin')) return -1;
        if (!a.role.contains('admin') && b.role.contains('admin')) return 1;
        return a.displayName.compareTo(b.displayName);
      });

      availableUsers.value = users;
    } catch (e) {
      Logger.error('Error loading available users', e);
    }
  }

  void changeTargetUser(UserModel? user) {
    if (user == null) return;
    selectedUser.value = user;
    // Reload stats
    loadWeeklyIbadahData();
    if (selectedTabIndex.value == 2) {
      loadMonthlyIbadahData(focusedDay.value);
    }
    // Also reload ranking if needed, though ranking is usually global
    // loadUserRanking(); // Ranking might be specific to the logged in user context?
    // Usually ranking shows where "I" am. If viewing others, maybe show "Their" rank.
    _loadUserRankingForTarget(user);
  }

  Future<void> _loadUserRankingForTarget(UserModel target) async {
    // Logic similar to loadUserRanking but for specific user
    try {
      // Ambil leaderboard semua users individual (ketua kelompok 1-5 + admin + kedisiplinan + super admin)
      final leaderboard = await _firestore.getLevelBasedLeaderboard();
      // Total users adalah jumlah semua users di leaderboard (maksimal 8: 5 ketua + admin + kedisiplinan + super admin)
      totalUsersInGroup.value = leaderboard.length;

      // Cari ranking user target
      for (int i = 0; i < leaderboard.length; i++) {
        if (leaderboard[i]['userId'] == target.uid) {
          userRank.value = i + 1;
          break;
        }
      }

      // Jika tidak ditemukan, set rank ke 0
      if (userRank.value == 0 && leaderboard.isNotEmpty) {
        userRank.value = 0;
      }
    } catch (e) {
      Logger.error('Error loading user ranking', e);
      userRank.value = 0;
      totalUsersInGroup.value = 0;
    }
  }

  // Amalan Yaumi methods
  Future<void> loadWeeklyIbadahData() async {
    try {
      isLoadingWeeklyIbadah.value = true;
      final targetUid = selectedUser.value?.uid;
      final data = await _ibadahService.getWeeklyIbadahData(userId: targetUid);
      // Keep original order: oldest day (left) → newest day (right)
      weeklyIbadahData.value = data;
      _calculateIbadahStatistics(weeklyIbadahData);
      _calculateIbadahStreak(weeklyIbadahData);
      _calculateIbadahSholatStatistics(weeklyIbadahData);
      // Load running stats
      await _loadRunningStats();
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
      final targetUid = selectedUser.value?.uid;
      final data = await _ibadahService.getMonthlyIbadahData(
        month,
        userId: targetUid,
      );
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
        amalanCounts['Al-Waqi\'ah (56)'] =
            (amalanCounts['Al-Waqi\'ah (56)'] ?? 0) + 1;
      }
      if (dayData.alkahfiOrYasin == true) {
        amalanCounts['Al-Kahfi / Yasin'] =
            (amalanCounts['Al-Kahfi / Yasin'] ?? 0) + 1;
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
    final sortedData = List<DailyIbadahModel>.from(data)
      ..sort((a, b) {
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
      final dayNormalized = DateTime.utc(
        dateParsed.year,
        dateParsed.month,
        dateParsed.day,
      );

      // Check if this is a consecutive day
      final expectedDate = todayNormalized.subtract(Duration(days: i));

      if (dayNormalized == expectedDate &&
          dayData.calculateLevelPercentage() > 0) {
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
    // Always initialize with all three statistics
    sholatStatistics.value = {'jamaah': 0.0, 'qobliyah': 0.0, 'badiyah': 0.0};

    if (data.isEmpty) {
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

  /// Load user ranking berdasarkan level individual user
  /// Menghitung ketua kelompok 1-5 + admin + kedisiplinan + super admin (maksimal 8 users)
  Future<void> loadUserRanking() async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        return;
      }

      // Ambil leaderboard semua users individual (ketua kelompok 1-5 + admin + kedisiplinan + super admin)
      final leaderboard = await _firestore.getLevelBasedLeaderboard();
      // Total users adalah jumlah semua users di leaderboard (maksimal 8: 5 ketua + admin + kedisiplinan + super admin)
      totalUsersInGroup.value = leaderboard.length;

      // Cari ranking user saat ini (berdasarkan userId, bukan kelompokId)
      for (int i = 0; i < leaderboard.length; i++) {
        if (leaderboard[i]['userId'] == user.uid) {
          userRank.value = i + 1;
          break;
        }
      }

      // Jika tidak ditemukan, set rank ke 0
      if (userRank.value == 0 && leaderboard.isNotEmpty) {
        userRank.value = 0;
      }
    } catch (e) {
      Logger.error('Error loading user ranking', e);
      userRank.value = 0;
      totalUsersInGroup.value = 0;
    }
  }

  /// Load running statistics
  Future<void> _loadRunningStats() async {
    try {
      final monthlyTotal = await _runningService.getMonthlyTotal();
      final streak = await _runningService.getStreak();
      monthlyRunningDays.value = monthlyTotal;
      runningStreak.value = streak;
    } catch (e) {
      Logger.error('Error loading running stats', e);
      monthlyRunningDays.value = 0;
      runningStreak.value = 0;
    }
  }
}
