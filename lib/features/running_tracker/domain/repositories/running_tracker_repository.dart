import '../entities/running_log.dart';

/// Abstract Running Tracker Repository
abstract class RunningTrackerRepository {
  /// Save a running log
  Future<void> saveRunningLog(RunningLog log);

  /// Get running logs for a user
  Future<List<RunningLog>> getRunningLogsByUser(String userId);

  /// Get running logs for a date
  Future<List<RunningLog>> getRunningLogsByDate(DateTime date);
}
