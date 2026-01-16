/// Model for individual weekend task with day option
class WeekendTaskItem {
  final String name;

  /// Day option: 'sabtu', 'ahad', or 'both'
  final String dayOption;

  const WeekendTaskItem({required this.name, this.dayOption = 'both'});

  factory WeekendTaskItem.fromJson(Map<String, dynamic> json) {
    return WeekendTaskItem(
      name: json['name'] as String? ?? '',
      dayOption: json['dayOption'] as String? ?? 'both',
    );
  }

  /// Parse from legacy string format (migration support)
  factory WeekendTaskItem.fromString(String taskName) {
    return WeekendTaskItem(name: taskName, dayOption: 'both');
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'dayOption': dayOption};
  }

  WeekendTaskItem copyWith({String? name, String? dayOption}) {
    return WeekendTaskItem(
      name: name ?? this.name,
      dayOption: dayOption ?? this.dayOption,
    );
  }

  /// Check if this task should be shown on a given day
  bool isVisibleOnDay(String day) {
    if (dayOption == 'both') return true;
    return dayOption == day.toLowerCase();
  }

  /// Get display label for day option
  String get dayLabel {
    switch (dayOption) {
      case 'sabtu':
        return 'Sabtu';
      case 'ahad':
        return 'Ahad';
      case 'both':
      default:
        return 'Sabtu & Ahad';
    }
  }

  /// Get short label for badges
  String get dayBadge {
    switch (dayOption) {
      case 'sabtu':
        return 'S';
      case 'ahad':
        return 'A';
      case 'both':
      default:
        return 'S+A';
    }
  }

  @override
  String toString() => 'WeekendTaskItem(name: $name, day: $dayOption)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeekendTaskItem &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          dayOption == other.dayOption;

  @override
  int get hashCode => name.hashCode ^ dayOption.hashCode;
}
