import '../entities/study_time_record.dart';
import '../repositories/study_time_repository.dart';

/// Use Case: Load study time records
class LoadStudyTimeRecordsUseCase {
  final StudyTimeRepository repository;

  LoadStudyTimeRecordsUseCase(this.repository);

  /// Load record for a specific date and kelompok
  Future<StudyTimeRecord?> loadDayRecord({
    required String date,
    required int kelompokId,
  }) async {
    return await repository.getRecord(date, kelompokId);
  }

  /// Load records for current week
  Future<List<StudyTimeRecord>> loadWeekRecords({
    required int kelompokId,
  }) async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    return await repository.getRecords(
      kelompokId: kelompokId,
      startDate: weekStart,
      endDate: weekEnd,
    );
  }

  /// Load records for current month
  Future<List<StudyTimeRecord>> loadMonthRecords({
    required int kelompokId,
  }) async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    return await repository.getRecords(
      kelompokId: kelompokId,
      startDate: monthStart,
      endDate: monthEnd,
    );
  }

  /// Load records for a custom date range
  Future<List<StudyTimeRecord>> loadRecordsInRange({
    required int kelompokId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await repository.getRecords(
      kelompokId: kelompokId,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
