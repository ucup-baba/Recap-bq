import '../../core/utils/date_utils.dart';
import '../../core/utils/logger.dart';
import 'auth_service.dart';
import 'firestore_service.dart';
import '../models/daily_ibadah_model.dart';

class IbadahTrackingService {
  IbadahTrackingService._();
  static final IbadahTrackingService instance = IbadahTrackingService._();

  final _firestore = FirestoreService.instance;
  final _authService = AuthService.instance;

  /// Save/update daily ibadah with all fields
  Future<void> saveDailyIbadah({
    // Sholat Wajib
    bool? subuhQobliyah,
    bool? subuhJamaah,
    bool? dzuhurJamaah,
    bool? dzuhurBadiyah,
    bool? asharJamaah,
    bool? maghribJamaah,
    bool? maghribBadiyah,
    bool? isyaJamaah,
    bool? isyaBadiyah,
    // Amalan Harian
    bool? sholatDhuha,
    bool? alMulk,
    bool? tahajud,
    bool? surah56,
    bool? alkahfiOrYasin,
    // Fisik
    int? pushup,
    String? notes,
  }) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        Logger.warning('User not logged in, cannot save ibadah');
        return;
      }

      final today = AppDateUtils.formatDate(DateTime.now());
      await _firestore.saveDailyIbadah(
        user.uid,
        today,
        // Sholat Wajib
        subuhQobliyah: subuhQobliyah,
        subuhJamaah: subuhJamaah,
        dzuhurJamaah: dzuhurJamaah,
        dzuhurBadiyah: dzuhurBadiyah,
        asharJamaah: asharJamaah,
        maghribJamaah: maghribJamaah,
        maghribBadiyah: maghribBadiyah,
        isyaJamaah: isyaJamaah,
        isyaBadiyah: isyaBadiyah,
        // Amalan Harian
        sholatDhuha: sholatDhuha,
        alMulk: alMulk,
        tahajud: tahajud,
        surah56: surah56,
        alkahfiOrYasin: alkahfiOrYasin,
        // Fisik
        pushup: pushup,
        notes: notes,
      );
      Logger.info('Daily ibadah saved successfully');
    } catch (e) {
      Logger.error('Error saving daily ibadah', e);
      rethrow;
    }
  }

  /// Get daily ibadah for today
  Future<DailyIbadahModel?> getTodayIbadah() async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        return null;
      }

      final today = AppDateUtils.formatDate(DateTime.now());
      return await _firestore.getDailyIbadah(user.uid, today);
    } catch (e) {
      Logger.error('Error getting today ibadah', e);
      return null;
    }
  }

  /// Get daily ibadah for specific date
  Future<DailyIbadahModel?> getDailyIbadahForDate(DateTime date) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        return null;
      }

      final dateStr = AppDateUtils.formatDate(date);
      return await _firestore.getDailyIbadah(user.uid, dateStr);
    } catch (e) {
      Logger.error('Error getting ibadah for date', e);
      return null;
    }
  }

  /// Get weekly ibadah data
  Future<List<DailyIbadahModel>> getWeeklyIbadahData({String? userId}) async {
    try {
      final user = _authService.currentUser;
      final targetUid = userId ?? user?.uid;

      if (targetUid == null) {
        return [];
      }

      return await _firestore.getWeeklyIbadahData(targetUid, DateTime.now());
    } catch (e) {
      Logger.error('Error getting weekly ibadah data', e);
      return [];
    }
  }

  /// Get monthly ibadah data
  Future<Map<DateTime, DailyIbadahModel>> getMonthlyIbadahData(
    DateTime month, {
    String? userId,
  }) async {
    try {
      final user = _authService.currentUser;
      final targetUid = userId ?? user?.uid;

      if (targetUid == null) {
        return {};
      }

      return await _firestore.getMonthlyIbadahData(targetUid, month);
    } catch (e) {
      Logger.error('Error getting monthly ibadah data', e);
      return {};
    }
  }

  // Helper methods for individual fields update
  Future<void> updateSubuhQobliyah(bool value) async {
    await saveDailyIbadah(subuhQobliyah: value);
  }

  Future<void> updateSubuhJamaah(bool value) async {
    await saveDailyIbadah(subuhJamaah: value);
  }

  Future<void> updateDzuhurJamaah(bool value) async {
    await saveDailyIbadah(dzuhurJamaah: value);
  }

  Future<void> updateDzuhurBadiyah(bool value) async {
    await saveDailyIbadah(dzuhurBadiyah: value);
  }

  Future<void> updateAsharJamaah(bool value) async {
    await saveDailyIbadah(asharJamaah: value);
  }

  Future<void> updateMaghribJamaah(bool value) async {
    await saveDailyIbadah(maghribJamaah: value);
  }

  Future<void> updateMaghribBadiyah(bool value) async {
    await saveDailyIbadah(maghribBadiyah: value);
  }

  Future<void> updateIsyaJamaah(bool value) async {
    await saveDailyIbadah(isyaJamaah: value);
  }

  Future<void> updateIsyaBadiyah(bool value) async {
    await saveDailyIbadah(isyaBadiyah: value);
  }

  Future<void> updateSholatDhuha(bool value) async {
    await saveDailyIbadah(sholatDhuha: value);
  }

  Future<void> updateAlMulk(bool value) async {
    await saveDailyIbadah(alMulk: value);
  }

  Future<void> updateTahajud(bool value) async {
    await saveDailyIbadah(tahajud: value);
  }

  Future<void> updateSurah56(bool value) async {
    await saveDailyIbadah(surah56: value);
  }

  Future<void> updateAlkahfiOrYasin(bool value) async {
    await saveDailyIbadah(alkahfiOrYasin: value);
  }

  Future<void> updatePushup(int value) async {
    await saveDailyIbadah(pushup: value);
  }

  Future<void> updateNotes(String value) async {
    await saveDailyIbadah(notes: value);
  }
}
