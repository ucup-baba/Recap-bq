/// Study Time Domain Entity
/// Pure Dart class with no external dependencies
///
/// Attendance status for study time
enum AttendanceStatus {
  hadir, // Present
  sakit, // Sick
  ijin, // Permission with note
}

/// Extension for AttendanceStatus
extension AttendanceStatusExtension on AttendanceStatus {
  String get label {
    switch (this) {
      case AttendanceStatus.hadir:
        return 'Hadir';
      case AttendanceStatus.sakit:
        return 'Sakit';
      case AttendanceStatus.ijin:
        return 'Ijin';
    }
  }
}

/// Individual attendance record for a santri
class StudyAttendance {
  final String userId;
  final String displayName;
  final AttendanceStatus status;
  final String? note; // Required for ijin status

  const StudyAttendance({
    required this.userId,
    required this.displayName,
    required this.status,
    this.note,
  });

  StudyAttendance copyWith({
    String? userId,
    String? displayName,
    AttendanceStatus? status,
    String? note,
  }) {
    return StudyAttendance(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      status: status ?? this.status,
      note: note ?? this.note,
    );
  }
}

/// Study Time record for a specific date and kelompok
class StudyTimeRecord {
  final String id; // Format: {date}_{kelompokId}
  final String date; // Format: yyyy-MM-dd
  final int kelompokId;
  final String recordedBy; // userId of coordinator who recorded
  final DateTime? recordedAt;
  final List<StudyAttendance> attendances;

  const StudyTimeRecord({
    required this.id,
    required this.date,
    required this.kelompokId,
    required this.recordedBy,
    this.recordedAt,
    required this.attendances,
  });

  /// Get statistics for this record
  AttendanceStats get stats {
    int hadir = 0, sakit = 0, ijin = 0;
    for (final a in attendances) {
      switch (a.status) {
        case AttendanceStatus.hadir:
          hadir++;
          break;
        case AttendanceStatus.sakit:
          sakit++;
          break;
        case AttendanceStatus.ijin:
          ijin++;
          break;
      }
    }
    return AttendanceStats(
      hadir: hadir,
      sakit: sakit,
      ijin: ijin,
      total: attendances.length,
    );
  }

  StudyTimeRecord copyWith({
    String? id,
    String? date,
    int? kelompokId,
    String? recordedBy,
    DateTime? recordedAt,
    List<StudyAttendance>? attendances,
  }) {
    return StudyTimeRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      kelompokId: kelompokId ?? this.kelompokId,
      recordedBy: recordedBy ?? this.recordedBy,
      recordedAt: recordedAt ?? this.recordedAt,
      attendances: attendances ?? this.attendances,
    );
  }
}

/// Attendance statistics
class AttendanceStats {
  final int hadir;
  final int sakit;
  final int ijin;
  final int total;

  const AttendanceStats({
    required this.hadir,
    required this.sakit,
    required this.ijin,
    required this.total,
  });
}
