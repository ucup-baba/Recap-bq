// Study Time Model - for mandatory study hour attendance tracking
// Schedule: Monday-Friday, 20:00-21:00 at Aula Asrama
import 'package:cloud_firestore/cloud_firestore.dart';

/// Attendance status enum
enum AttendanceStatus {
  hadir, // Present
  sakit, // Sick
  ijin, // Permission with note
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

  factory StudyAttendance.fromMap(Map<String, dynamic> map) {
    return StudyAttendance(
      userId: map['userId'] ?? '',
      displayName: map['displayName'] ?? '',
      status: AttendanceStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AttendanceStatus.hadir,
      ),
      note: map['note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'status': status.name,
      if (note != null && note!.isNotEmpty) 'note': note,
    };
  }

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
  final String recordedBy; // userId of ketua who recorded
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

  factory StudyTimeRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudyTimeRecord(
      id: doc.id,
      date: data['date'] ?? '',
      kelompokId: data['kelompokId'] ?? 0,
      recordedBy: data['recordedBy'] ?? '',
      recordedAt: (data['recordedAt'] as Timestamp?)?.toDate(),
      attendances:
          (data['attendances'] as List<dynamic>?)
              ?.map((e) => StudyAttendance.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'kelompokId': kelompokId,
      'recordedBy': recordedBy,
      'recordedAt': FieldValue.serverTimestamp(),
      'attendances': attendances.map((e) => e.toMap()).toList(),
    };
  }

  /// Get statistics for this record
  Map<String, int> get stats {
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
    return {
      'hadir': hadir,
      'sakit': sakit,
      'ijin': ijin,
      'total': attendances.length,
    };
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

/// Weekly summary for study time
class StudyTimeWeeklySummary {
  final int weekNumber;
  final int year;
  final int kelompokId;
  final Map<String, Map<String, int>>
  memberStats; // userId -> {hadir, sakit, ijin}
  final int totalDays;

  const StudyTimeWeeklySummary({
    required this.weekNumber,
    required this.year,
    required this.kelompokId,
    required this.memberStats,
    required this.totalDays,
  });
}

/// Monthly summary for study time
class StudyTimeMonthlySummary {
  final int month;
  final int year;
  final int kelompokId;
  final Map<String, Map<String, int>>
  memberStats; // userId -> {hadir, sakit, ijin}
  final int totalDays;

  const StudyTimeMonthlySummary({
    required this.month,
    required this.year,
    required this.kelompokId,
    required this.memberStats,
    required this.totalDays,
  });
}
