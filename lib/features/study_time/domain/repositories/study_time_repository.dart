import '../entities/study_time_record.dart';

/// Abstract Study Time Repository Interface
/// Defines contract for study time operations
abstract class StudyTimeRepository {
  /// Get study time record for specific date and kelompok
  Future<StudyTimeRecord?> getRecord(String date, int kelompokId);

  /// Get study time records for a date range
  Future<List<StudyTimeRecord>> getRecords({
    required int kelompokId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Save or update study time record
  Future<void> saveRecord(StudyTimeRecord record);

  /// Get kelompok members for study time
  Future<List<Map<String, dynamic>>> getKelompokMembers(int kelompokId);

  /// Watch study time records (realtime updates)
  Stream<List<StudyTimeRecord>> watchRecords({
    required int kelompokId,
    DateTime? startDate,
    DateTime? endDate,
  });
}
