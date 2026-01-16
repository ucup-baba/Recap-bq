import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/utils/error_handler.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/task_model.dart';
import '../../data/models/weekend_area_tasks_model.dart';
import '../../data/models/weekend_report_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firestore_service.dart';
import '../../data/services/weekend_rotation_service.dart';
import '../../widgets/executor_bottom_sheet.dart';

class WeekendReportInputController extends GetxController {
  final _firestore = FirestoreService.instance;
  final _authService = AuthService.instance;
  final _rotationService = WeekendRotationService.instance;
  final _picker = ImagePicker();

  // User info
  final Rxn<int> kelompokId = Rxn<int>();
  final RxString kelompokName = ''.obs;

  // Current weekend
  final Rx<DateTime> currentWeekend = DateTime.now().obs;
  final Rx<WeekendSlotInfo?> slotInfo = Rx<WeekendSlotInfo?>(null);

  // Selected report type
  final RxString selectedReportType = 'masak'.obs;

  // Tasks with executors (like weekday)
  final RxList<TaskModel> tasks = <TaskModel>[].obs;

  // Members for executor selection
  final RxList<String> members = <String>[].obs;

  // Photo
  final Rxn<File> selectedPhoto = Rxn<File>();
  final RxString photoUrl = ''.obs;
  final RxBool isUploadingPhoto = false.obs;

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

      // Load members for executor selection
      await _loadMembers();

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

      // Set available report types based on slot and current day
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

  Future<void> _loadMembers() async {
    try {
      if (kelompokId.value == null) return;
      final data = await _firestore.getMembers(kelompokId.value!);
      if (data != null && data.members.isNotEmpty) {
        members.value = data.members;
      }
    } catch (e) {
      Logger.error('Error loading members', e);
    }
  }

  void _setupAvailableReportTypes(WeekendSlotInfo slot) {
    final types = <String>[];
    final today = DateTime.now();
    final isSaturday = today.weekday == DateTime.saturday;
    final isSunday = today.weekday == DateTime.sunday;

    if (isSaturday) {
      if (slot.hasCooking && slot.slotName.toLowerCase().contains('sabtu')) {
        types.add('masak');
      }
      types.add('piket_sabtu');
    } else if (isSunday) {
      if (slot.hasCooking && slot.slotName.toLowerCase().contains('ahad')) {
        types.add('masak');
      }
      types.add('piket_ahad');
    } else {
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

      // Determine area and day based on report type
      String area;
      String day;
      if (selectedReportType.value == 'masak') {
        area = 'Masak';
        day = 'both'; // Masak tasks apply to both days
      } else if (selectedReportType.value == 'piket_sabtu') {
        area = slot.piketAreaSabtu;
        day = 'sabtu';
      } else {
        area = slot.piketAreaAhad;
        day = 'ahad';
      }

      // Load task data from Firestore filtered by day
      List<Map<String, dynamic>> taskData = await _firestore
          .getWeekendAreaTasksForDay(area, day);

      // If no tasks, use defaults filtered by day
      if (taskData.isEmpty) {
        final defaults = WeekendAreaTasksModel.getDefaultTasksForArea(area);
        taskData = defaults
            .where((t) => t.dayOption == 'both' || t.dayOption == day)
            .map((t) => t.toJson())
            .toList();
      }

      // Extract task names
      final taskNames = taskData.map((t) => t['name'] as String).toList();

      // Try to load existing report first
      final reportId = WeekendReportModel.generateId(
        currentWeekend.value,
        kelompokId.value!,
        selectedReportType.value,
      );
      final existingData = await _firestore.getWeekendReport(reportId);

      if (existingData != null) {
        existingReport.value = WeekendReportModel.fromJson(existingData);
        tasks.value = existingReport.value!.tasks;
        photoUrl.value = existingReport.value!.photoUrl ?? '';
      } else {
        existingReport.value = null;
        // Initialize tasks with empty executors
        tasks.value = taskNames
            .map(
              (name) => TaskModel(taskName: name, isDone: false, executors: []),
            )
            .toList();
        photoUrl.value = '';
      }

      selectedPhoto.value = null;
    } catch (e) {
      Logger.error('Error loading tasks', e);
    } finally {
      isLoading.value = false;
    }
  }

  void toggleTask(int index) {
    final task = tasks[index];
    tasks[index] = task.copyWith(isDone: !task.isDone);
    _autoSaveDraft();
  }

  Future<void> selectExecutors(int index, BuildContext context) async {
    final task = tasks[index];
    final selected = await ExecutorBottomSheet.pick(members: members);

    if (selected != null) {
      tasks[index] = task.copyWith(
        executors: selected,
        isDone: selected.isNotEmpty,
      );
      _autoSaveDraft();
    }
  }

  Future<void> _autoSaveDraft() async {
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
      photoUrl: photoUrl.value.isNotEmpty ? photoUrl.value : null,
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

      // Check if all tasks have executors
      final hasUnassignedTasks = tasks.any((t) => t.executors.isEmpty);
      if (hasUnassignedTasks) {
        SnackbarHelper.showWarning('Mohon pilih pelaksana untuk setiap task');
        return;
      }

      // Check if photo is uploaded
      if (photoUrl.value.isEmpty) {
        SnackbarHelper.showWarning('Mohon upload foto bukti');
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

  // Photo handling
  Future<void> pickPhotoFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        await _processAndUploadPhoto(File(image.path));
      }
    } catch (e) {
      Logger.error('Error picking photo from camera', e);
      SnackbarHelper.showError('Gagal mengambil foto');
    }
  }

  Future<void> pickPhotoFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        await _processAndUploadPhoto(File(image.path));
      }
    } catch (e) {
      Logger.error('Error picking photo from gallery', e);
      SnackbarHelper.showError('Gagal memilih foto');
    }
  }

  Future<void> _processAndUploadPhoto(File file) async {
    try {
      isUploadingPhoto.value = true;
      selectedPhoto.value = file;

      // Compress image
      final compressedFile = await compressImage(file);

      // Upload to Firebase Storage
      final url = await _firestore.uploadWeekendReportPhoto(
        compressedFile,
        kelompokId.value!,
        selectedReportType.value,
        currentWeekend.value,
      );

      photoUrl.value = url;
      await _autoSaveDraft();

      SnackbarHelper.showSuccess('Foto berhasil diupload');
    } catch (e) {
      Logger.error('Error uploading photo', e);
      SnackbarHelper.showError('Gagal mengupload foto');
      selectedPhoto.value = null;
    } finally {
      isUploadingPhoto.value = false;
    }
  }

  Future<File> compressImage(File file) async {
    final filePath = file.absolute.path;
    final lastIndex = filePath.lastIndexOf(RegExp(r'.jp'));
    final splitted = filePath.substring(0, lastIndex);
    final outPath = '${splitted}_compressed.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      outPath,
      quality: 70,
      minWidth: 800,
      minHeight: 800,
    );

    return result != null ? File(result.path) : file;
  }

  void deletePhoto() {
    selectedPhoto.value = null;
    photoUrl.value = '';
    _autoSaveDraft();
  }

  double get completionPercentage {
    if (tasks.isEmpty) return 0;
    final completed = tasks
        .where((t) => t.isDone && t.executors.isNotEmpty)
        .length;
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
