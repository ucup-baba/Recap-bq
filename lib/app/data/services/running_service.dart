import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/running_log_model.dart';
import 'auth_service.dart';

/// Service untuk tracking lari harian
class RunningService {
  RunningService._();
  static final RunningService instance = RunningService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _authService = AuthService.instance;

  CollectionReference get _runningLogsRef =>
      _firestore.collection('running_logs');

  /// Get running log untuk hari ini
  Future<RunningLogModel?> getTodayLog() async {
    final user = _authService.currentUser;
    if (user == null) return null;

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _runningLogsRef
        .where('odooId', isEqualTo: user.uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return RunningLogModel.fromMap(
      snapshot.docs.first.data() as Map<String, dynamic>,
      snapshot.docs.first.id,
    );
  }

  /// Toggle status lari hari ini
  Future<bool> toggleTodayRunning() async {
    final user = _authService.currentUser;
    if (user == null) return false;

    final todayLog = await getTodayLog();

    if (todayLog == null) {
      // Buat log baru dengan status completed
      await _runningLogsRef.add(
        RunningLogModel(
          id: '',
          odooId: user.uid,
          odooName: user.displayName ?? 'User',
          date: DateTime.now(),
          isCompleted: true,
          completedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ).toMap(),
      );
      return true;
    } else {
      // Toggle status
      final newStatus = !todayLog.isCompleted;
      await _runningLogsRef.doc(todayLog.id).update({
        'isCompleted': newStatus,
        'completedAt': newStatus ? Timestamp.fromDate(DateTime.now()) : null,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return newStatus;
    }
  }

  /// Get weekly running logs (7 hari terakhir)
  Future<List<RunningLogModel>> getWeeklyLogs() async {
    final user = _authService.currentUser;
    if (user == null) return [];

    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));

    final snapshot = await _runningLogsRef
        .where('odooId', isEqualTo: user.uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map(
          (doc) => RunningLogModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          ),
        )
        .toList();
  }

  /// Get streak lari (berturut-turut hari)
  Future<int> getStreak() async {
    final user = _authService.currentUser;
    if (user == null) return 0;

    final snapshot = await _runningLogsRef
        .where('odooId', isEqualTo: user.uid)
        .where('isCompleted', isEqualTo: true)
        .orderBy('date', descending: true)
        .limit(30) // Max 30 hari
        .get();

    if (snapshot.docs.isEmpty) return 0;

    int streak = 0;
    DateTime? lastDate;

    for (final doc in snapshot.docs) {
      final log = RunningLogModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );

      if (lastDate == null) {
        // First entry
        final today = DateTime.now();
        final logDate = DateTime(log.date.year, log.date.month, log.date.day);
        final todayDate = DateTime(today.year, today.month, today.day);
        final yesterdayDate = todayDate.subtract(const Duration(days: 1));

        // Harus hari ini atau kemarin
        if (logDate == todayDate || logDate == yesterdayDate) {
          streak = 1;
          lastDate = logDate;
        } else {
          break;
        }
      } else {
        final logDate = DateTime(log.date.year, log.date.month, log.date.day);
        final expectedDate = lastDate.subtract(const Duration(days: 1));

        if (logDate == expectedDate) {
          streak++;
          lastDate = logDate;
        } else {
          break;
        }
      }
    }

    return streak;
  }

  /// Get total lari bulan ini
  Future<int> getMonthlyTotal() async {
    final user = _authService.currentUser;
    if (user == null) return 0;

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final snapshot = await _runningLogsRef
        .where('odooId', isEqualTo: user.uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('isCompleted', isEqualTo: true)
        .get();

    return snapshot.docs.length;
  }
}
