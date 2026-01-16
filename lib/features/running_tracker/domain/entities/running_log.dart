/// Running Tracker Entity
class RunningLog {
  final String id;
  final String userId;
  final String userName;
  final DateTime runDate;
  final int lapCount;
  final Duration totalDuration;
  final List<LapTime> laps;

  const RunningLog({
    required this.id,
    required this.userId,
    required this.userName,
    required this.runDate,
    required this.lapCount,
    required this.totalDuration,
    required this.laps,
  });
}

class LapTime {
  final int lapNumber;
  final Duration duration;

  const LapTime({required this.lapNumber, required this.duration});
}
