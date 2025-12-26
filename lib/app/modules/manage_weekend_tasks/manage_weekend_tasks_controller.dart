import 'dart:async';

import 'package:get/get.dart';

import '../../core/utils/error_handler.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/weekend_area_tasks_model.dart';
import '../../data/services/firestore_service.dart';
import '../../widgets/task_form_dialog.dart';

class ManageWeekendTasksController extends GetxController {
  final _firestore = FirestoreService.instance;

  /// Available weekend areas + Masak
  final List<String> areas = [
    'Masak',
    'Halaman',
    'Kamar Aula',
    'Tempat Wudhu',
    'Rongsokan',
    'Masjid',
    'Dapur',
  ];

  final selectedArea = 'Masak'.obs;
  final tasks = <String>[].obs;
  final isLoading = false.obs;

  StreamSubscription<List<String>>? _tasksSubscription;

  @override
  void onInit() {
    super.onInit();
    // Seed defaults if needed
    _seedDefaultsIfNeeded();
    loadAreaTasks(selectedArea.value);
  }

  @override
  void onClose() {
    _tasksSubscription?.cancel();
    super.onClose();
  }

  Future<void> _seedDefaultsIfNeeded() async {
    try {
      await _firestore.seedDefaultWeekendTasks();
    } catch (e) {
      Logger.warning('Error seeding weekend tasks: $e');
    }
  }

  void loadAreaTasks(String area) {
    selectedArea.value = area;
    _tasksSubscription?.cancel();
    _tasksSubscription = _firestore
        .watchWeekendAreaTasks(area)
        .listen(
          (List<String> data) {
            if (data.isEmpty) {
              // Use defaults if no custom tasks
              tasks.assignAll(
                WeekendAreaTasksModel.getDefaultTasksForArea(area),
              );
            } else {
              tasks.assignAll(data);
            }
          },
          onError: (error) {
            Logger.error('Error loading weekend area tasks', error);
            SnackbarHelper.showError(ErrorHandler.getErrorMessage(error));
            // Fallback to defaults
            tasks.assignAll(WeekendAreaTasksModel.getDefaultTasksForArea(area));
          },
        );
  }

  Future<void> addTask() async {
    final name = await TaskFormDialog.open();
    if (name == null) return;
    try {
      tasks.add(name);
      await _firestore.saveWeekendAreaTasks(selectedArea.value, tasks.toList());
      Logger.info('Weekend task added: $name');
      SnackbarHelper.showSuccess('Task berhasil ditambahkan');
    } catch (e) {
      Logger.error('Error adding weekend task', e);
      tasks.removeLast(); // Rollback
      SnackbarHelper.showError(ErrorHandler.getErrorMessage(e));
    }
  }

  Future<void> editTask(int index) async {
    final name = await TaskFormDialog.open(initialValue: tasks[index]);
    if (name == null) return;
    final oldName = tasks[index];
    try {
      tasks[index] = name;
      await _firestore.saveWeekendAreaTasks(selectedArea.value, tasks.toList());
      Logger.info('Weekend task updated: $oldName -> $name');
      SnackbarHelper.showSuccess('Task berhasil diperbarui');
    } catch (e) {
      Logger.error('Error editing weekend task', e);
      tasks[index] = oldName; // Rollback
      SnackbarHelper.showError(ErrorHandler.getErrorMessage(e));
    }
  }

  Future<void> deleteTask(int index) async {
    final deletedTask = tasks[index];
    try {
      tasks.removeAt(index);
      await _firestore.saveWeekendAreaTasks(selectedArea.value, tasks.toList());
      Logger.info('Weekend task deleted: $deletedTask');
      SnackbarHelper.showSuccess('Task berhasil dihapus');
    } catch (e) {
      Logger.error('Error deleting weekend task', e);
      tasks.insert(index, deletedTask); // Rollback
      SnackbarHelper.showError(ErrorHandler.getErrorMessage(e));
    }
  }

  Future<void> resetToDefaults() async {
    try {
      final defaults = WeekendAreaTasksModel.getDefaultTasksForArea(
        selectedArea.value,
      );
      tasks.assignAll(defaults);
      await _firestore.saveWeekendAreaTasks(selectedArea.value, defaults);
      Logger.info('Weekend tasks reset to defaults: ${selectedArea.value}');
      SnackbarHelper.showSuccess('Task dikembalikan ke default');
    } catch (e) {
      Logger.error('Error resetting weekend tasks', e);
      SnackbarHelper.showError(ErrorHandler.getErrorMessage(e));
    }
  }
}
