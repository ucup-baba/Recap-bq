import 'package:get/get.dart';

import '../../data/models/daily_ibadah_model.dart';

/// Interface untuk controller yang menangani tracking ibadah
/// Diimplementasikan oleh SantriDashboardController dan AdminIbadahController
abstract class IbadahControllerInterface {
  /// Get ibadah data untuk hari ini
  DailyIbadahModel? todayIbadah();

  /// Load ibadah data untuk hari ini
  Future<void> loadTodayIbadah();

  /// Update ibadah data
  Future<void> updateIbadah(DailyIbadahModel updatedIbadah);

  /// Show motivation dialog untuk sholat
  void showSholatMotivation();

  /// Show motivation dialog untuk amalan
  void showAmalanMotivation();

  /// Pushup motivation text (observable)
  RxString get pushupMotivation;
}

