import 'package:intl/intl.dart';

/// Service for calculating weekend (Saturday-Sunday) rotation schedules.
///
/// The rotation system:
/// - 4 cooking slots: Sabtu Pagi, Sabtu Malam, Ahad Pagi, Ahad Malam
/// - 5 kelompok, so 1 kelompok doesn't cook each weekend (gets Dapur duty)
/// - Each cooking slot is paired with a fixed piket area
/// - Rotation shifts by 1 position each week
class WeekendRotationService {
  WeekendRotationService._();
  static final WeekendRotationService instance = WeekendRotationService._();

  /// Reference date: First Saturday of rotation (August 2, 2025)
  /// This is Week 0 with order: [4, 5, 1, 2, 3]
  static final DateTime referenceDate = DateTime(2025, 8, 2);

  /// Slot names for cooking
  static const List<String> masakSlots = [
    'Sabtu Pagi',
    'Sabtu Malam',
    'Ahad Pagi',
    'Ahad Malam',
  ];

  /// Weekend piket areas (5 areas for 5 kelompok)
  static const List<String> piketAreas = [
    'Halaman',
    'Kamar Aula',
    'Tempat Wudhu', // Sabtu only, becomes Rongsokan on Ahad
    'Masjid',
    'Dapur', // For kelompok that doesn't cook
  ];

  /// Fixed pairing: Masak slot index → Piket area
  /// Index 4 is special: no cooking, just Dapur piket
  static const Map<int, String> slotToPiketArea = {
    0: 'Halaman', // Sabtu Pagi
    1: 'Kamar Aula', // Sabtu Malam
    2: 'Tempat Wudhu', // Ahad Pagi (Sabtu: Wudhu, Ahad: Rongsokan)
    3: 'Masjid', // Ahad Malam
    4: 'Dapur', // No cooking
  };

  /// Base order for Week 0 (August 2-3, 2025): [4, 5, 1, 2, 3]
  static const List<int> baseOrder = [4, 5, 1, 2, 3];

  /// Get the Saturday date for a given date's weekend.
  /// If the date is Sunday, returns the previous Saturday.
  DateTime getSaturdayForDate(DateTime date) {
    if (date.weekday == DateTime.saturday) {
      return DateTime(date.year, date.month, date.day);
    } else if (date.weekday == DateTime.sunday) {
      return DateTime(date.year, date.month, date.day - 1);
    }
    // For other days, calculate next Saturday
    final daysUntilSaturday = DateTime.saturday - date.weekday;
    return DateTime(date.year, date.month, date.day + daysUntilSaturday);
  }

  /// Calculate week number from reference date
  int calculateWeekNumber(DateTime saturday) {
    final normalizedSaturday = DateTime(
      saturday.year,
      saturday.month,
      saturday.day,
    );
    final normalizedReference = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    );
    final difference = normalizedSaturday
        .difference(normalizedReference)
        .inDays;
    return (difference / 7).floor();
  }

  /// Get kelompok ID for a specific slot in a specific week
  ///
  /// Formula: ((baseOrder[slotIndex] - 1 - weekNumber) % 5) + 1
  /// This makes the rotation shift backward by 1 each week
  int getKelompokForSlot(int slotIndex, int weekNumber) {
    final base = baseOrder[slotIndex];
    // Handle negative modulo correctly
    int result = ((base - 1 - weekNumber) % 5);
    if (result < 0) result += 5;
    return result + 1;
  }

  /// Get full weekend schedule for a specific Saturday date
  WeekendSchedule getScheduleForDate(DateTime date) {
    final saturday = getSaturdayForDate(date);
    final weekNumber = calculateWeekNumber(saturday);

    return WeekendSchedule(
      weekendDate: saturday,
      weekNumber: weekNumber,
      sabtuPagi: getKelompokForSlot(0, weekNumber),
      sabtuMalam: getKelompokForSlot(1, weekNumber),
      ahadPagi: getKelompokForSlot(2, weekNumber),
      ahadMalam: getKelompokForSlot(3, weekNumber),
      dapur: getKelompokForSlot(4, weekNumber),
    );
  }

  /// Get the slot info for a specific kelompok on a specific weekend
  WeekendSlotInfo? getSlotForKelompok(int kelompokId, DateTime date) {
    final schedule = getScheduleForDate(date);

    if (schedule.sabtuPagi == kelompokId) {
      return WeekendSlotInfo(
        slotName: 'Sabtu Pagi',
        slotIndex: 0,
        hasCooking: true,
        piketArea: 'Halaman',
        piketAreaSabtu: 'Halaman',
        piketAreaAhad: 'Halaman',
      );
    } else if (schedule.sabtuMalam == kelompokId) {
      return WeekendSlotInfo(
        slotName: 'Sabtu Malam',
        slotIndex: 1,
        hasCooking: true,
        piketArea: 'Kamar Aula',
        piketAreaSabtu: 'Kamar Aula',
        piketAreaAhad: 'Kamar Aula',
      );
    } else if (schedule.ahadPagi == kelompokId) {
      return WeekendSlotInfo(
        slotName: 'Ahad Pagi',
        slotIndex: 2,
        hasCooking: true,
        piketArea: 'Tempat Wudhu / Rongsokan',
        piketAreaSabtu: 'Tempat Wudhu',
        piketAreaAhad: 'Rongsokan',
      );
    } else if (schedule.ahadMalam == kelompokId) {
      return WeekendSlotInfo(
        slotName: 'Ahad Malam',
        slotIndex: 3,
        hasCooking: true,
        piketArea: 'Masjid',
        piketAreaSabtu: 'Masjid',
        piketAreaAhad: 'Masjid',
      );
    } else if (schedule.dapur == kelompokId) {
      return WeekendSlotInfo(
        slotName: 'Dapur',
        slotIndex: 4,
        hasCooking: false,
        piketArea: 'Dapur',
        piketAreaSabtu: 'Dapur',
        piketAreaAhad: 'Dapur',
      );
    }

    return null;
  }

  /// Check if a date is a weekend day (Saturday or Sunday)
  bool isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  /// Format weekend date range as string
  String formatWeekendRange(DateTime saturday) {
    final sunday = saturday.add(const Duration(days: 1));
    final formatter = DateFormat('d MMM', 'id_ID');
    return '${formatter.format(saturday)} - ${formatter.format(sunday)}';
  }
}

/// Represents the full weekend schedule
class WeekendSchedule {
  final DateTime weekendDate;
  final int weekNumber;
  final int sabtuPagi;
  final int sabtuMalam;
  final int ahadPagi;
  final int ahadMalam;
  final int dapur;

  WeekendSchedule({
    required this.weekendDate,
    required this.weekNumber,
    required this.sabtuPagi,
    required this.sabtuMalam,
    required this.ahadPagi,
    required this.ahadMalam,
    required this.dapur,
  });

  /// Get kelompok ID by slot index
  int getKelompokBySlot(int slotIndex) {
    switch (slotIndex) {
      case 0:
        return sabtuPagi;
      case 1:
        return sabtuMalam;
      case 2:
        return ahadPagi;
      case 3:
        return ahadMalam;
      case 4:
        return dapur;
      default:
        throw ArgumentError('Invalid slot index: $slotIndex');
    }
  }

  @override
  String toString() {
    return 'WeekendSchedule(week: $weekNumber, sabtuPagi: $sabtuPagi, sabtuMalam: $sabtuMalam, ahadPagi: $ahadPagi, ahadMalam: $ahadMalam, dapur: $dapur)';
  }
}

/// Information about a kelompok's slot for a weekend
class WeekendSlotInfo {
  final String slotName;
  final int slotIndex;
  final bool hasCooking;
  final String piketArea;
  final String piketAreaSabtu;
  final String piketAreaAhad;

  WeekendSlotInfo({
    required this.slotName,
    required this.slotIndex,
    required this.hasCooking,
    required this.piketArea,
    required this.piketAreaSabtu,
    required this.piketAreaAhad,
  });
}
