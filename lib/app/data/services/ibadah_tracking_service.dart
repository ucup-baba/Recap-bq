import '../../core/utils/date_utils.dart';
import '../../core/utils/logger.dart';
import 'auth_service.dart';
import 'firestore_service.dart';

class IbadahTrackingService {
  IbadahTrackingService._();
  static final IbadahTrackingService instance = IbadahTrackingService._();

  final _firestore = FirestoreService.instance;
  final _authService = AuthService.instance;

  /// Save/update daily ibadah
  Future<void> saveDailyIbadah({
    bool? sholatDhuha,
    bool? alMulk,
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
        sholatDhuha: sholatDhuha,
        alMulk: alMulk,
      );
      Logger.info('Daily ibadah saved: sholatDhuha=$sholatDhuha, alMulk=$alMulk');
    } catch (e) {
      Logger.error('Error saving daily ibadah', e);
      rethrow;
    }
  }

  /// Get daily ibadah for today
  Future<Map<String, bool?>> getTodayIbadah() async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        return {'sholat_dhuha': null, 'al_mulk': null};
      }

      final today = AppDateUtils.formatDate(DateTime.now());
      return await _firestore.getDailyIbadah(user.uid, today);
    } catch (e) {
      Logger.error('Error getting today ibadah', e);
      return {'sholat_dhuha': null, 'al_mulk': null};
    }
  }

  /// Update sholat dhuha status
  Future<void> updateSholatDhuha(bool value) async {
    await saveDailyIbadah(sholatDhuha: value);
  }

  /// Update al-mulk status
  Future<void> updateAlMulk(bool value) async {
    await saveDailyIbadah(alMulk: value);
  }
}
