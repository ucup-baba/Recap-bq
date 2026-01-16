import '../../domain/entities/weekend_task.dart';

/// Weekend Task Item Model (DTO)
class WeekendTaskItemModel {
  final String name;
  final String dayOption;

  const WeekendTaskItemModel({required this.name, this.dayOption = 'both'});

  factory WeekendTaskItemModel.fromJson(Map<String, dynamic> json) {
    return WeekendTaskItemModel(
      name: json['name'] as String? ?? '',
      dayOption: json['dayOption'] as String? ?? 'both',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'dayOption': dayOption};
  }

  /// Convert DTO to domain entity
  WeekendTaskItem toEntity() {
    return WeekendTaskItem(
      name: name,
      dayOption: DayOptionExtension.fromString(dayOption),
    );
  }

  /// Convert domain entity to DTO
  static WeekendTaskItemModel fromEntity(WeekendTaskItem entity) {
    return WeekendTaskItemModel(
      name: entity.name,
      dayOption: entity.dayOption.value,
    );
  }
}

/// Weekend Area Tasks Model (DTO)
class WeekendAreaTasksModel {
  final String areaId;
  final String areaName;
  final List<WeekendTaskItemModel> tasks;

  const WeekendAreaTasksModel({
    required this.areaId,
    required this.areaName,
    required this.tasks,
  });

  factory WeekendAreaTasksModel.fromJson(Map<String, dynamic> json) {
    return WeekendAreaTasksModel(
      areaId: json['areaId'] as String? ?? '',
      areaName: json['areaName'] as String? ?? '',
      tasks:
          (json['tasks'] as List<dynamic>?)
              ?.map(
                (e) => WeekendTaskItemModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'areaId': areaId,
      'areaName': areaName,
      'tasks': tasks.map((e) => e.toJson()).toList(),
    };
  }

  /// Convert DTO to domain entity
  WeekendAreaTasks toEntity() {
    return WeekendAreaTasks(
      areaId: areaId,
      areaName: areaName,
      tasks: tasks.map((e) => e.toEntity()).toList(),
    );
  }

  /// Convert domain entity to DTO
  static WeekendAreaTasksModel fromEntity(WeekendAreaTasks entity) {
    return WeekendAreaTasksModel(
      areaId: entity.areaId,
      areaName: entity.areaName,
      tasks: entity.tasks
          .map((e) => WeekendTaskItemModel.fromEntity(e))
          .toList(),
    );
  }
}
