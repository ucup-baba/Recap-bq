import 'dart:async';

import 'package:get/get.dart';

import '../../core/utils/error_handler.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/area_tasks_model.dart';
import '../../data/services/firestore_service.dart';
import '../../data/services/rotation_service.dart';
import '../../widgets/task_form_dialog.dart';

class ManageTasksController extends GetxController {
  final _firestore = FirestoreService.instance;
  final _rotation = RotationService();
  late final List<String> areas = _rotation.areas;

  final selectedArea = 'Kamar'.obs;
  final tasks = <String>[].obs;

  StreamSubscription<AreaTasksModel?>? _tasksSubscription;

  @override
  void onInit() {
    super.onInit();
    loadAreaTasks(selectedArea.value);
  }

  @override
  void onClose() {
    _tasksSubscription?.cancel();
    super.onClose();
  }

  void loadAreaTasks(String area) {
    selectedArea.value = area;
    _tasksSubscription?.cancel();
    _tasksSubscription = _firestore
        .watchAreaTasks(area)
        .listen(
          (AreaTasksModel? data) {
            tasks.assignAll(data?.tasks ?? []);
          },
          onError: (error) {
            Logger.error('Error loading area tasks', error);
            SnackbarHelper.showError(ErrorHandler.getErrorMessage(error));
          },
        );
  }

  Future<void> addTask() async {
    final name = await TaskFormDialog.open();
    if (name == null) return;
    try {
      tasks.add(name);
      await _firestore.upsertAreaTasks(selectedArea.value, tasks);
      Logger.info('Task added: $name');
      SnackbarHelper.showSuccess('Task berhasil ditambahkan');
    } catch (e) {
      Logger.error('Error adding task', e);
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
      await _firestore.upsertAreaTasks(selectedArea.value, tasks);
      Logger.info('Task updated: $oldName -> $name');
      SnackbarHelper.showSuccess('Task berhasil diperbarui');
    } catch (e) {
      Logger.error('Error editing task', e);
      tasks[index] = oldName; // Rollback
      SnackbarHelper.showError(ErrorHandler.getErrorMessage(e));
    }
  }

  Future<void> deleteTask(int index) async {
    final deletedTask = tasks[index];
    try {
      tasks.removeAt(index);
      await _firestore.upsertAreaTasks(selectedArea.value, tasks);
      Logger.info('Task deleted: $deletedTask');
      SnackbarHelper.showSuccess('Task berhasil dihapus');
    } catch (e) {
      Logger.error('Error deleting task', e);
      tasks.insert(index, deletedTask); // Rollback
      SnackbarHelper.showError(ErrorHandler.getErrorMessage(e));
    }
  }
}
