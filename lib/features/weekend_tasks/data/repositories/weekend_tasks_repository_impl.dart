import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/data/datasources/firestore_datasource.dart';
import '../../domain/entities/weekend_task.dart';
import '../../domain/repositories/weekend_tasks_repository.dart';
import '../models/weekend_task_model.dart';

/// Implementation of WeekendTasksRepository
class WeekendTasksRepositoryImpl implements WeekendTasksRepository {
  final FirestoreDataSource firestoreDataSource;

  WeekendTasksRepositoryImpl({required this.firestoreDataSource});

  static const String _collection = 'weekend_area_tasks';

  @override
  Future<WeekendAreaTasks?> getAreaTasks(String areaId) async {
    final firestore = FirebaseFirestore.instance;

    try {
      final doc = await firestore.collection(_collection).doc(areaId).get();

      if (!doc.exists || doc.data() == null) return null;

      final model = WeekendAreaTasksModel.fromJson(doc.data()!);
      return model.toEntity();
    } catch (e) {
      throw Exception('Failed to get area tasks: $e');
    }
  }

  @override
  Future<List<WeekendAreaTasks>> getAllAreaTasks() async {
    final firestore = FirebaseFirestore.instance;

    try {
      final snapshot = await firestore.collection(_collection).get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['areaId'] = doc.id; // Ensure areaId is set from doc ID
        return WeekendAreaTasksModel.fromJson(data).toEntity();
      }).toList();
    } catch (e) {
      throw Exception('Failed to get all area tasks: $e');
    }
  }

  @override
  Future<void> updateAreaTasks(WeekendAreaTasks areaTasks) async {
    final model = WeekendAreaTasksModel.fromEntity(areaTasks);
    await firestoreDataSource.setDocument(
      _collection,
      areaTasks.areaId,
      model.toJson(),
      merge: true,
    );
  }

  @override
  Future<void> addTaskToArea(String areaId, WeekendTaskItem task) async {
    final firestore = FirebaseFirestore.instance;

    try {
      final docRef = firestore.collection(_collection).doc(areaId);
      final taskModel = WeekendTaskItemModel.fromEntity(task);

      await docRef.update({
        'tasks': FieldValue.arrayUnion([taskModel.toJson()]),
      });
    } catch (e) {
      throw Exception('Failed to add task to area: $e');
    }
  }

  @override
  Future<void> removeTaskFromArea(String areaId, String taskName) async {
    try {
      // Get current area tasks
      final areaTasks = await getAreaTasks(areaId);
      if (areaTasks == null) {
        throw Exception('Area not found');
      }

      // Filter out the task to remove
      final updatedTasks = areaTasks.tasks
          .where((task) => task.name != taskName)
          .toList();

      // Update with filtered list
      await updateAreaTasks(areaTasks.copyWith(tasks: updatedTasks));
    } catch (e) {
      throw Exception('Failed to remove task from area: $e');
    }
  }

  @override
  Future<void> updateTask(
    String areaId,
    String oldTaskName,
    WeekendTaskItem newTask,
  ) async {
    try {
      // Get current area tasks
      final areaTasks = await getAreaTasks(areaId);
      if (areaTasks == null) {
        throw Exception('Area not found');
      }

      // Update the specific task
      final updatedTasks = areaTasks.tasks.map((task) {
        if (task.name == oldTaskName) {
          return newTask;
        }
        return task;
      }).toList();

      // Save updated list
      await updateAreaTasks(areaTasks.copyWith(tasks: updatedTasks));
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }
}
