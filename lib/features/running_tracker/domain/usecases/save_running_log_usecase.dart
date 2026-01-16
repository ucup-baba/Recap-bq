import '../entities/running_log.dart';
import '../repositories/running_tracker_repository.dart';

/// Use Case: Save Running Log
class SaveRunningLogUseCase {
  final RunningTrackerRepository repository;

  SaveRunningLogUseCase(this.repository);

  Future<void> call({
    required String userId,
    required String userName,
    required int lapCount,
    required Duration totalDuration,
    required List<LapTime> laps,
  }) async {
    if (userId.trim().isEmpty) {
      throw ArgumentError('User ID cannot be empty');
    }

    if (lapCount < 1) {
      throw ArgumentError('Lap count must be at least 1');
    }

    final log = RunningLog(
      id: '',
      userId: userId,
      userName: userName,
      runDate: DateTime.now(),
      lapCount: lapCount,
      totalDuration: totalDuration,
      laps: laps,
    );

    await repository.saveRunningLog(log);
  }
}
