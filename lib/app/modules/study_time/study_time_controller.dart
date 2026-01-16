import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routes/app_pages.dart';
import '../../core/utils/logger.dart';
import '../../data/models/study_time_model.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firestore_service.dart';

class StudyTimeController extends GetxController {
  final _firestoreService = FirestoreService.instance;
  final _authService = AuthService.instance;

  // Observables
  final isLoading = true.obs;
  final isSaving = false.obs;
  final isKetua = false.obs;
  final currentDate = DateTime.now().obs;
  final members = <Map<String, dynamic>>[].obs;
  final attendances = <String, StudyAttendance>{}.obs;
  final existingRecord = Rxn<StudyTimeRecord>();
  final currentUser = Rxn<UserModel>();

  // View mode: 'today', 'week', 'month'
  final viewMode = 'today'.obs;
  final weeklyRecords = <StudyTimeRecord>[].obs;
  final monthlyRecords = <StudyTimeRecord>[].obs;

  int? get kelompokId => currentUser.value?.kelompokId;
  String? get oderId => _authService.currentUser?.uid;
  String? get displayName => currentUser.value?.displayName;

  bool get isWeekday {
    final dayOfWeek = currentDate.value.weekday;
    return dayOfWeek >= 1 && dayOfWeek <= 5; // Monday = 1, Friday = 5
  }

  String get formattedDate {
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(currentDate.value);
  }

  String get dateString {
    return DateFormat('yyyy-MM-dd').format(currentDate.value);
  }

  @override
  void onInit() {
    super.onInit();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        Get.offAllNamed(AppRoutes.auth);
        return;
      }

      // Fetch user data from Firestore
      final userData = await _firestoreService.fetchUser(user.uid);
      if (userData != null) {
        currentUser.value = userData;

        // Check if user is ketua kelompok (koordinator role)
        isKetua.value = userData.role == AppConstants.userRoleKoordinator;
        Logger.info(
          'StudyTimeController: User ${userData.displayName} isKetua: ${isKetua.value}, kelompokId: ${userData.kelompokId}',
        );

        // Load data after we have user info
        await _loadData();
      }
    } catch (e) {
      Logger.error('StudyTimeController: Error loading user', e);
    }
  }

  Future<void> _loadData() async {
    try {
      isLoading.value = true;

      if (kelompokId == null) {
        Logger.warning('StudyTimeController: No kelompokId found');
        isLoading.value = false;
        return;
      }

      // Load members
      final membersList = await _firestoreService
          .getKelompokMembersForStudyTime(kelompokId!);
      members.value = membersList;
      Logger.info('StudyTimeController: Loaded ${members.length} members');

      // Load existing record for today
      await _loadTodayRecord();

      // If no existing record, initialize attendances with default (hadir)
      if (existingRecord.value == null) {
        _initializeAttendances();
      }
    } catch (e) {
      Logger.error('StudyTimeController: Error loading data', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadTodayRecord() async {
    if (kelompokId == null) return;

    final record = await _firestoreService.getStudyTimeRecord(
      dateString,
      kelompokId!,
    );
    existingRecord.value = record;

    if (record != null) {
      // Populate attendances from existing record
      for (final att in record.attendances) {
        attendances[att.userId] = att;
      }
      Logger.info(
        'StudyTimeController: Loaded existing record with ${record.attendances.length} attendances',
      );
    }
  }

  void _initializeAttendances() {
    attendances.clear();
    for (final member in members) {
      final oderId = member['userId'] as String;
      final memberName = member['displayName'] as String;
      attendances[oderId] = StudyAttendance(
        userId: oderId,
        displayName: memberName,
        status: AttendanceStatus.hadir,
      );
    }
  }

  void updateAttendanceStatus(
    String oderId,
    AttendanceStatus status, {
    String? note,
  }) {
    final current = attendances[oderId];
    if (current != null) {
      attendances[oderId] = current.copyWith(status: status, note: note);
    }
  }

  Future<void> saveAttendance() async {
    if (!isKetua.value) {
      Get.snackbar(
        'Error',
        'Hanya Ketua Kelompok yang dapat menyimpan kehadiran',
      );
      return;
    }

    if (!isWeekday) {
      Get.snackbar('Info', 'Jam wajib belajar hanya hari Senin-Jumat');
      return;
    }

    try {
      isSaving.value = true;

      final record = StudyTimeRecord(
        id: '${dateString}_$kelompokId',
        date: dateString,
        kelompokId: kelompokId!,
        recordedBy: oderId ?? '',
        attendances: attendances.values.toList(),
      );

      await _firestoreService.saveStudyTimeRecord(record);
      existingRecord.value = record;

      Get.snackbar('Sukses', 'Kehadiran berhasil disimpan');
      Logger.info(
        'StudyTimeController: Saved attendance for ${attendances.length} members',
      );
    } catch (e) {
      Logger.error('StudyTimeController: Error saving attendance', e);
      Get.snackbar('Error', 'Gagal menyimpan kehadiran');
    } finally {
      isSaving.value = false;
    }
  }

  // === Weekly & Monthly History ===

  Future<void> loadWeeklyHistory() async {
    if (kelompokId == null) return;

    try {
      // Get start of current week (Monday)
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));

      final records = await _firestoreService.getStudyTimeRecords(
        kelompokId: kelompokId!,
        startDate: weekStart,
        endDate: weekEnd,
      );

      weeklyRecords.value = records;
      Logger.info(
        'StudyTimeController: Loaded ${records.length} weekly records',
      );
    } catch (e) {
      Logger.error('StudyTimeController: Error loading weekly history', e);
    }
  }

  Future<void> loadMonthlyHistory() async {
    if (kelompokId == null) return;

    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0);

      final records = await _firestoreService.getStudyTimeRecords(
        kelompokId: kelompokId!,
        startDate: monthStart,
        endDate: monthEnd,
      );

      monthlyRecords.value = records;
      Logger.info(
        'StudyTimeController: Loaded ${records.length} monthly records',
      );
    } catch (e) {
      Logger.error('StudyTimeController: Error loading monthly history', e);
    }
  }

  void changeViewMode(String mode) {
    viewMode.value = mode;
    if (mode == 'week') {
      loadWeeklyHistory();
    } else if (mode == 'month') {
      loadMonthlyHistory();
    }
  }

  void changeDate(DateTime newDate) {
    currentDate.value = newDate;
    _loadTodayRecord();
  }

  // Get attendance stats for a member across records
  Map<String, int> getMemberStats(
    String oderId,
    List<StudyTimeRecord> records,
  ) {
    int hadir = 0, sakit = 0, ijin = 0;

    for (final record in records) {
      for (final att in record.attendances) {
        if (att.userId == oderId) {
          switch (att.status) {
            case AttendanceStatus.hadir:
              hadir++;
              break;
            case AttendanceStatus.sakit:
              sakit++;
              break;
            case AttendanceStatus.ijin:
              ijin++;
              break;
          }
        }
      }
    }

    return {'hadir': hadir, 'sakit': sakit, 'ijin': ijin};
  }

  // Get detailed history for a member across records
  List<Map<String, dynamic>> getMemberDetailedHistory(
    String userId,
    List<StudyTimeRecord> records,
  ) {
    final history = <Map<String, dynamic>>[];

    for (final record in records) {
      for (final att in record.attendances) {
        if (att.userId == userId) {
          history.add({
            'date': record.date,
            'status': att.status,
            'note': att.note,
          });
        }
      }
    }

    // Sort by date descending (newest first)
    history.sort(
      (a, b) => (b['date'] as String).compareTo(a['date'] as String),
    );

    return history;
  }
}
