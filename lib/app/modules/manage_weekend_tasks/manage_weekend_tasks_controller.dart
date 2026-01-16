import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/utils/error_handler.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/weekend_area_tasks_model.dart';
import '../../data/models/weekend_task_item.dart';
import '../../data/services/firestore_service.dart';

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
  final tasks = <WeekendTaskItem>[].obs;
  final isLoading = false.obs;

  /// Day filter: 'semua', 'sabtu', 'ahad'
  final dayFilter = 'semua'.obs;

  /// Get filtered tasks based on dayFilter
  List<WeekendTaskItem> get filteredTasks {
    if (dayFilter.value == 'semua') {
      return tasks.toList();
    } else if (dayFilter.value == 'sabtu') {
      // Sabtu filter: show 'sabtu' and 'both', exclude 'ahad' only
      return tasks.where((t) => t.dayOption != 'ahad').toList();
    } else {
      // Ahad filter: show 'ahad' and 'both', exclude 'sabtu' only
      return tasks.where((t) => t.dayOption != 'sabtu').toList();
    }
  }

  StreamSubscription<List<Map<String, dynamic>>>? _tasksSubscription;

  @override
  void onInit() {
    super.onInit();
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
          (List<Map<String, dynamic>> data) {
            if (data.isEmpty) {
              // Use defaults if no custom tasks
              tasks.assignAll(
                WeekendAreaTasksModel.getDefaultTasksForArea(area),
              );
            } else {
              tasks.assignAll(
                data.map((m) => WeekendTaskItem.fromJson(m)).toList(),
              );
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

  /// Add a new task with day option dialog
  Future<void> addTask() async {
    final result = await _showTaskDialog();
    if (result == null) return;

    try {
      final newTask = WeekendTaskItem(
        name: result['name'] as String,
        dayOption: result['dayOption'] as String,
      );
      tasks.add(newTask);
      await _saveCurrentTasks();
      Logger.info('Weekend task added: ${newTask.name} (${newTask.dayOption})');
      SnackbarHelper.showSuccess('Task berhasil ditambahkan');
    } catch (e) {
      Logger.error('Error adding weekend task', e);
      tasks.removeLast(); // Rollback
      SnackbarHelper.showError(ErrorHandler.getErrorMessage(e));
    }
  }

  /// Edit task at index
  Future<void> editTask(int index) async {
    final currentTask = tasks[index];
    final result = await _showTaskDialog(
      initialName: currentTask.name,
      initialDayOption: currentTask.dayOption,
    );
    if (result == null) return;

    final oldTask = tasks[index];
    try {
      tasks[index] = WeekendTaskItem(
        name: result['name'] as String,
        dayOption: result['dayOption'] as String,
      );
      await _saveCurrentTasks();
      Logger.info(
        'Weekend task updated: ${oldTask.name} -> ${tasks[index].name}',
      );
      SnackbarHelper.showSuccess('Task berhasil diperbarui');
    } catch (e) {
      Logger.error('Error editing weekend task', e);
      tasks[index] = oldTask; // Rollback
      SnackbarHelper.showError(ErrorHandler.getErrorMessage(e));
    }
  }

  /// Delete task at index
  Future<void> deleteTask(int index) async {
    final deletedTask = tasks[index];
    try {
      tasks.removeAt(index);
      await _saveCurrentTasks();
      Logger.info('Weekend task deleted: ${deletedTask.name}');
      SnackbarHelper.showSuccess('Task berhasil dihapus');
    } catch (e) {
      Logger.error('Error deleting weekend task', e);
      tasks.insert(index, deletedTask); // Rollback
      SnackbarHelper.showError(ErrorHandler.getErrorMessage(e));
    }
  }

  /// Reset to default tasks
  Future<void> resetToDefaults() async {
    try {
      final defaults = WeekendAreaTasksModel.getDefaultTasksForArea(
        selectedArea.value,
      );
      tasks.assignAll(defaults);
      await _saveCurrentTasks();
      Logger.info('Weekend tasks reset to defaults: ${selectedArea.value}');
      SnackbarHelper.showSuccess('Task dikembalikan ke default');
    } catch (e) {
      Logger.error('Error resetting weekend tasks', e);
      SnackbarHelper.showError(ErrorHandler.getErrorMessage(e));
    }
  }

  /// Save current tasks to Firestore
  Future<void> _saveCurrentTasks() async {
    final taskMaps = tasks.map((t) => t.toJson()).toList();
    await _firestore.saveWeekendAreaTasks(selectedArea.value, taskMaps);
  }

  /// Show dialog to add/edit task with day option
  Future<Map<String, String>?> _showTaskDialog({
    String? initialName,
    String? initialDayOption,
  }) async {
    final nameController = TextEditingController(text: initialName ?? '');
    final selectedDayOption = (initialDayOption ?? 'both').obs;

    return Get.dialog<Map<String, String>>(
      AlertDialog(
        title: Text(initialName == null ? 'Tambah Task' : 'Edit Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Task',
                hintText: 'Masukkan nama task',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            const Text(
              'Berlaku untuk hari:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Obx(
              () => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildDayChip('both', 'S + A', selectedDayOption),
                  _buildDayChip('sabtu', 'Sabtu', selectedDayOption),
                  _buildDayChip('ahad', 'Ahad', selectedDayOption),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                SnackbarHelper.showError('Nama task tidak boleh kosong');
                return;
              }
              Get.back(
                result: {'name': name, 'dayOption': selectedDayOption.value},
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Widget _buildDayChip(String value, String label, RxString selected) {
    final isSelected = selected.value == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => selected.value = value,
    );
  }
}
