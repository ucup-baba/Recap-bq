import '../entities/study_time_record.dart';
import '../repositories/study_time_repository.dart';

/// Use Case: Save study time attendance record
/// Handles validation and business logic for saving
class SaveStudyTimeUseCase {
  final StudyTimeRepository repository;

  SaveStudyTimeUseCase(this.repository);

  /// Execute save
  /// Validates that:
  /// - Date is a weekday (Monday-Friday)
  /// - Recorder is a ketua kelompok
  /// - All attendances have required fields
  Future<void> call({
    required String date,
    required int kelompokId,
    required String recordedBy,
    required List<StudyAttendance> attendances,
  }) async {
    // Validation
    if (attendances.isEmpty) {
      throw ArgumentError('Attendances cannot be empty');
    }

    if (recordedBy.trim().isEmpty) {
      throw ArgumentError('Recorded by cannot be empty');
    }

    if (kelompokId < 1) {
      throw ArgumentError('Invalid kelompok ID');
    }

    // Validate date format (yyyy-MM-dd)
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
      throw ArgumentError('Invalid date format. Use yyyy-MM-dd');
    }

    // Parse date and check if it's a weekday
    final dateTime = DateTime.parse(date);
    final dayOfWeek = dateTime.weekday;
    if (dayOfWeek < 1 || dayOfWeek > 5) {
      throw ArgumentError('Study time is only for weekdays (Monday-Friday)');
    }

    // Validate attendances
    for (final attendance in attendances) {
      if (attendance.userId.trim().isEmpty) {
        throw ArgumentError('User ID cannot be empty');
      }
      if (attendance.displayName.trim().isEmpty) {
        throw ArgumentError('Display name cannot be empty');
      }
      // Ijin status must have a note
      if (attendance.status == AttendanceStatus.ijin &&
          (attendance.note == null || attendance.note!.trim().isEmpty)) {
        throw ArgumentError('Note is required for ijin status');
      }
    }

    // Create record
    final record = StudyTimeRecord(
      id: '${date}_$kelompokId',
      date: date,
      kelompokId: kelompokId,
      recordedBy: recordedBy,
      attendances: attendances,
      recordedAt: DateTime.now(),
    );

    // Save to repository
    await repository.saveRecord(record);
  }
}
