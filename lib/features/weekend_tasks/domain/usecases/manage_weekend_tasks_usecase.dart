import '../entities/weekend_task.dart';
import '../repositories/weekend_tasks_repository.dart';

/// Use Case: Manage weekend tasks for areas
class ManageWeekendTasksUseCase {
  final WeekendTasksRepository repository;

  ManageWeekendTasksUseCase(this.repository);

  /// Get all area tasks
  Future<List<WeekendAreaTasks>> getAllTasks() async {
    return await repository.getAllAreaTasks();
  }

  /// Add a new task to an area
  Future<void> addTask({
    required String areaId,
    required String taskName,
    DayOption dayOption = DayOption.both,
  }) async {
    if (taskName.trim().isEmpty) {
      throw ArgumentError('Task name cannot be empty');
    }

    if (areaId.trim().isEmpty) {
      throw ArgumentError('Area ID cannot be empty');
    }

    final task = WeekendTaskItem(name: taskName.trim(), dayOption: dayOption);

    await repository.addTaskToArea(areaId, task);
  }

  /// Update an existing task
  Future<void> updateTask({
    required String areaId,
    required String oldTaskName,
    required String newTaskName,
    required DayOption newDayOption,
  }) async {
    if (newTaskName.trim().isEmpty) {
      throw ArgumentError('Task name cannot be empty');
    }

    if (areaId.trim().isEmpty) {
      throw ArgumentError('Area ID cannot be empty');
    }

    final newTask = WeekendTaskItem(
      name: newTaskName.trim(),
      dayOption: newDayOption,
    );

    await repository.updateTask(areaId, oldTaskName, newTask);
  }

  /// Remove a task from an area
  Future<void> removeTask({
    required String areaId,
    required String taskName,
  }) async {
    if (taskName.trim().isEmpty) {
      throw ArgumentError('Task name cannot be empty');
    }

    if (areaId.trim().isEmpty) {
      throw ArgumentError('Area ID cannot be empty');
    }

    await repository.removeTaskFromArea(areaId, taskName);
  }

  /// Get tasks for a specific day (filter by day option)
  List<WeekendTaskItem> getTasksForDay(
    List<WeekendTaskItem> tasks,
    String day,
  ) {
    return tasks.where((task) => task.isVisibleOnDay(day)).toList();
  }
}
