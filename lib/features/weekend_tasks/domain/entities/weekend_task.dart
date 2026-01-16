/// Weekend Task Domain Entity
/// Pure Dart class with no external dependencies
///
/// Day option for weekend tasks
enum DayOption {
  sabtu, // Saturday only
  ahad, // Sunday only
  both, // Both days
}

/// Extension for DayOption
extension DayOptionExtension on DayOption {
  String get value {
    switch (this) {
      case DayOption.sabtu:
        return 'sabtu';
      case DayOption.ahad:
        return 'ahad';
      case DayOption.both:
        return 'both';
    }
  }

  String get label {
    switch (this) {
      case DayOption.sabtu:
        return 'Sabtu';
      case DayOption.ahad:
        return 'Ahad';
      case DayOption.both:
        return 'Sabtu & Ahad';
    }
  }

  String get badge {
    switch (this) {
      case DayOption.sabtu:
        return 'S';
      case DayOption.ahad:
        return 'A';
      case DayOption.both:
        return 'S+A';
    }
  }

  static DayOption fromString(String value) {
    switch (value.toLowerCase()) {
      case 'sabtu':
        return DayOption.sabtu;
      case 'ahad':
        return DayOption.ahad;
      default:
        return DayOption.both;
    }
  }
}

/// Individual weekend task item
class WeekendTaskItem {
  final String name;
  final DayOption dayOption;

  const WeekendTaskItem({required this.name, this.dayOption = DayOption.both});

  /// Check if this task should be shown on a given day
  bool isVisibleOnDay(String day) {
    if (dayOption == DayOption.both) return true;
    return dayOption.value == day.toLowerCase();
  }

  WeekendTaskItem copyWith({String? name, DayOption? dayOption}) {
    return WeekendTaskItem(
      name: name ?? this.name,
      dayOption: dayOption ?? this.dayOption,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeekendTaskItem &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          dayOption == other.dayOption;

  @override
  int get hashCode => name.hashCode ^ dayOption.hashCode;

  @override
  String toString() => 'WeekendTaskItem(name: $name, day: ${dayOption.value})';
}

/// Weekend area with assigned tasks
class WeekendAreaTasks {
  final String areaId;
  final String areaName;
  final List<WeekendTaskItem> tasks;

  const WeekendAreaTasks({
    required this.areaId,
    required this.areaName,
    required this.tasks,
  });

  WeekendAreaTasks copyWith({
    String? areaId,
    String? areaName,
    List<WeekendTaskItem>? tasks,
  }) {
    return WeekendAreaTasks(
      areaId: areaId ?? this.areaId,
      areaName: areaName ?? this.areaName,
      tasks: tasks ?? this.tasks,
    );
  }
}
