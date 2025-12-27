import 'dart:async';

import 'package:get/get.dart';

import '../../core/utils/error_handler.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/weekend_area_tasks_model.dart';
import '../../data/models/weekend_report_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firestore_service.dart';
import '../../data/services/weekend_rotation_service.dart';

class WeekendReportInputController extends GetxController {
  final _firestore = FirestoreService.instance;
  final _authService = AuthService.instance;
  final _rotationService = WeekendRotationService.instance;

  // User info
  final Rxn<int> kelompokId = Rxn<int>();
  final RxString kelompokName = ''.obs;

  // Current weekend
  final Rx<DateTime> currentWeekend = DateTime.now().obs;
  final Rx<WeekendSlotInfo?> slotInfo = Rx<WeekendSlotInfo?>(null);

  // Selected report type
  final RxString selectedReportType =
      'masak'.obs; // 'masak', 'piket_sabtu', 'piket_ahad'

  // Tasks and checklist
  final RxList<String> tasks = <String>[].obs;
  final RxMap<String, bool> checklist = <String, bool>{}.obs;

  // Form state
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final Rxn<WeekendReportModel> existingReport = Rxn<WeekendReportModel>();

  // Available report types for this kelompok's slot
  final RxList<String> availableReportTypes = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserAndSchedule();
  }

  Future<void> _loadUserAndSchedule() async {
    try {
      isLoading.value = true;

      // Get current user
      final user = _authService.currentUser;
      if (user == null) {
        SnackbarHelper.showError('User tidak ditemukan');
        Get.back();
        return;
      }

      // Fetch user profile to get kelompokId
      final profile = await _firestore.fetchUser(user.uid);
      if (profile == null || profile.kelompokId == null) {
        SnackbarHelper.showError('Kelompok tidak ditemukan');
        Get.back();
        return;
      }

      kelompokId.value = profile.kelompokId;
      kelompokName.value = 'Kelompok ${profile.kelompokId}';

      // Get current weekend's Saturday
      final today = DateTime.now();
      final saturday = _rotationService.getSaturdayForDate(today);
      currentWeekend.value = saturday;

      // Get slot info for this kelompok
      final slot = _rotationService.getSlotForKelompok(
        profile.kelompokId!,
        saturday,
      );
      if (slot == null) {
        SnackbarHelper.showError('Jadwal weekend tidak ditemukan');
        Get.back();
        return;
      }
      slotInfo.value = slot;

      // Set available report types based on slot
      _setupAvailableReportTypes(slot);

      // Load tasks for first available report type
      if (availableReportTypes.isNotEmpty) {
        await changeReportType(availableReportTypes.first);
      }
    } catch (e) {
      Logger.error('Error loading user and schedule', e);
      SnackbarHelper.showError(ErrorHandler.getErrorMessage(e));
    } finally {
      isLoading.value = false;
    }
  }

  void _setupAvailableReportTypes(WeekendSlotInfo slot) {
    final types = <String>[];
    final today = DateTime.now();
    final isSaturday = today.weekday == DateTime.saturday;
    final isSunday = today.weekday == DateTime.sunday;

    // On Saturday: show Masak (if applicable) + Piket Sabtu
    // On Sunday: show Masak (if applicable) + Piket Ahad
    if (isSaturday) {
      if (slot.hasCooking) {
        // Only show masak on Saturday if slot is Sabtu Pagi or Sabtu Malam
        if (slot.slotName.toLowerCase().contains('sabtu')) {
          types.add('masak');
        }
      }
      types.add('piket_sabtu');
    } else if (isSunday) {
      if (slot.hasCooking) {
        // Only show masak on Sunday if slot is Ahad Pagi or Ahad Malam
        if (slot.slotName.toLowerCase().contains('ahad')) {
          types.add('masak');
        }
      }
      types.add('piket_ahad');
    } else {
      // Not weekend - show all for preview/admin purposes
      if (slot.hasCooking) {
        types.add('masak');
      }
      types.add('piket_sabtu');
      types.add('piket_ahad');
    }

    availableReportTypes.value = types;
  }

  Future<void> changeReportType(String reportType) async {
    selectedReportType.value = reportType;
    await _loadTasksAndExistingReport();
  }

  Future<void> _loadTasksAndExistingReport() async {
    try {
      isLoading.value = true;

      final slot = slotInfo.value;
      if (slot == null) return;

      // Determine area based on report type
      String area;
      if (selectedReportType.value == 'masak') {
        area = 'Masak';
      } else if (selectedReportType.value == 'piket_sabtu') {
        area = slot.piketAreaSabtu;
      } else {
        area = slot.piketAreaAhad;
      }

      // Load tasks from Firestore (or use defaults)
      List<String> loadedTasks = await _firestore.getWeekendAreaTasks(area);
      if (loadedTasks.isEmpty) {
        loadedTasks = WeekendAreaTasksModel.getDefaultTasksForArea(area);
      }
      tasks.value = loadedTasks;

      // Initialize checklist
      checklist.value = {for (var task in loadedTasks) task: false};

      // Try to load existing report
      final reportId = WeekendReportModel.generateId(
        currentWeekend.value,
        kelompokId.value!,
        selectedReportType.value,
      );
      final existingData = await _firestore.getWeekendReport(reportId);
      if (existingData != null) {
        existingReport.value = WeekendReportModel.fromJson(existingData);
        // Restore checklist state
        final savedChecklist = existingReport.value!.checklist;
        for (var task in tasks) {
          if (savedChecklist.containsKey(task)) {
            checklist[task] = savedChecklist[task]!;
          }
        }
      } else {
        existingReport.value = null;
      }
    } catch (e) {
      Logger.error('Error loading tasks', e);
    } finally {
      isLoading.value = false;
    }
  }

  void toggleTask(String task) {
    if (checklist.containsKey(task)) {
      checklist[task] = !checklist[task]!;
      _autoSave();
    }
  }

  Future<void> _autoSave() async {
    // Save as draft automatically
    try {
      await _saveReport(asDraft: true);
    } catch (e) {
      Logger.warning('Auto-save failed: $e');
    }
  }

  Future<void> _saveReport({bool asDraft = false}) async {
    if (kelompokId.value == null || slotInfo.value == null) return;

    final slot = slotInfo.value!;
    String area;
    if (selectedReportType.value == 'masak') {
      area = 'Masak';
    } else if (selectedReportType.value == 'piket_sabtu') {
      area = slot.piketAreaSabtu;
    } else {
      area = slot.piketAreaAhad;
    }

    final reportId = WeekendReportModel.generateId(
      currentWeekend.value,
      kelompokId.value!,
      selectedReportType.value,
    );

    final report = WeekendReportModel(
      id: reportId,
      weekendDate: currentWeekend.value,
      kelompokId: kelompokId.value!,
      slot: slot.slotName.toLowerCase().replaceAll(' ', '_'),
      reportType: selectedReportType.value,
      area: area,
      tasks: tasks.toList(),
      checklist: Map<String, bool>.from(checklist),
      status: asDraft ? 'draft' : 'submitted',
      createdAt: existingReport.value?.createdAt ?? DateTime.now(),
      submittedAt: asDraft ? null : DateTime.now(),
    );

    await _firestore.saveWeekendReport(report.toJson());
    existingReport.value = report;
  }

  Future<void> submit() async {
    try {
      isSaving.value = true;

      // Check if all tasks are completed
      final allCompleted = checklist.values.every((v) => v);
      if (!allCompleted) {
        SnackbarHelper.showWarning(
          'Mohon selesaikan semua task terlebih dahulu',
        );
        return;
      }

      await _saveReport(asDraft: false);
      SnackbarHelper.showSuccess('Laporan berhasil disubmit!');

      // Move to next report type if available
      final currentIndex = availableReportTypes.indexOf(
        selectedReportType.value,
      );
      if (currentIndex < availableReportTypes.length - 1) {
        await changeReportType(availableReportTypes[currentIndex + 1]);
      }
    } catch (e) {
      Logger.error('Error submitting report', e);
      SnackbarHelper.showError(ErrorHandler.getErrorMessage(e));
    } finally {
      isSaving.value = false;
    }
  }

  double get completionPercentage {
    if (tasks.isEmpty) return 0;
    final completed = checklist.values.where((v) => v).length;
    return completed / tasks.length;
  }

  bool get isSubmitted => existingReport.value?.isSubmitted ?? false;

  String getReportTypeLabel(String type) {
    switch (type) {
      case 'masak':
        return 'Masak ${slotInfo.value?.slotName ?? ''}';
      case 'piket_sabtu':
        return 'Piket Sabtu (${slotInfo.value?.piketAreaSabtu ?? ''})';
      case 'piket_ahad':
        return 'Piket Ahad (${slotInfo.value?.piketAreaAhad ?? ''})';
      default:
        return type;
    }
  }
}
