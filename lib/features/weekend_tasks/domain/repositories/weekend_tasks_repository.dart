import '../entities/weekend_task.dart';

/// Abstract Weekend Tasks Repository Interface
/// Defines contract for weekend task operations
abstract class WeekendTasksRepository {
  /// Get tasks for a specific area
  Future<WeekendAreaTasks?> getAreaTasks(String areaId);

  /// Get all configured weekend areas with tasks
  Future<List<WeekendAreaTasks>> getAllAreaTasks();

  /// Update tasks for a specific area
  Future<void> updateAreaTasks(WeekendAreaTasks areaTasks);

  /// Add a new task to an area
  Future<void> addTaskToArea(String areaId, WeekendTaskItem task);

  /// Remove a task from an area
  Future<void> removeTaskFromArea(String areaId, String taskName);

  /// Update a specific task in an area
  Future<void> updateTask(
    String areaId,
    String oldTaskName,
    WeekendTaskItem newTask,
  );
}
