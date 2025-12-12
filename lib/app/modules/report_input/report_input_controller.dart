import 'dart:async';
import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routes/app_pages.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/daily_report_model.dart';
import '../../data/models/task_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firestore_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/rotation_service.dart';
import '../../widgets/executor_bottom_sheet.dart';

class ReportInputController extends GetxController {
  final _firestore = FirestoreService.instance;
  final _notificationService = NotificationService.instance;
  final _rotation = RotationService();

  final tasks = <TaskModel>[].obs;
  final members = <String>[].obs;
  final isSubmitting = false.obs;
  final isReadOnly = false.obs;
  final status = AppConstants.reportStatusDraft.obs;
  final _hasFetchedOnce = false.obs;
  final photoUrl = RxString('');
  final isUploadingPhoto = false.obs;
  final _imagePicker = ImagePicker();

  String area = '';
  int kelompokId = 0;
  String date = AppDateUtils.formatDate(DateTime.now());
  String get reportId => '$kelompokId-$date';

  StreamSubscription<List<DailyReportModel>>? _reportSubscription;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    area = args['area'] ?? '';
    kelompokId = args['kelompokId'] ?? 0;
    date = args['date'] ?? AppDateUtils.formatDate(DateTime.now());
    _loadMembers();
    _loadExistingReport();
  }

  Future<void> _loadTasks() async {
    final loaded = await _rotation.getTasksForArea(area);
    tasks.assignAll(
      loaded.map((e) => TaskModel(taskName: e, isDone: false, executors: [])),
    );
  }

  Future<void> _loadMembers() async {
    final data = await _firestore.getMembers(kelompokId);
    members.assignAll(data?.members ?? []);
  }

  @override
  void onClose() {
    _reportSubscription?.cancel();
    super.onClose();
  }

  Future<void> _loadExistingReport() async {
    _reportSubscription?.cancel();
    _hasFetchedOnce.value = false;

    // Fetch sekali dokumen langsung by ID untuk tampilkan status segera
    await _fetchExistingReportOnce();

    // Tetap dengarkan stream untuk update real-time (verified/rejected/reset oleh admin)
    _reportSubscription = _firestore
        .reportsByGroupAndDate(kelompokId, date)
        .listen(
          (existing) {
            _hasFetchedOnce.value = true;
            if (existing.isNotEmpty) {
              final report = existing.first;
              tasks.assignAll(report.tasks);
              area = report.areaTugas;
              status.value = report.status;
              photoUrl.value = report.photoUrl ?? '';
              // Lock when pending/verified; allow edit/resubmit if rejected/draft.
              isReadOnly.value =
                  report.status == AppConstants.reportStatusPending ||
                  report.status == AppConstants.reportStatusVerified;
              Logger.info(
                'Loaded existing report (stream): status=${report.status}, isReadOnly=$isReadOnly, photoUrl=${report.photoUrl}',
              );
            } else {
              // Dokumen tidak ada dari stream
              // Hanya set ke draft jika status sekarang bukan pending/verified
              // (untuk menghindari reset dari initial empty emit)
              if (status.value != AppConstants.reportStatusPending &&
                  status.value != AppConstants.reportStatusVerified) {
                Logger.info('No report found (stream), setting to draft');
                status.value = AppConstants.reportStatusDraft;
                isReadOnly.value = false;
                _loadTasks();
              }
            }
          },
          onError: (error) {
            Logger.error('Error loading existing report', error);
            // Hanya set ke draft jika status sekarang bukan pending/verified
            if (status.value != AppConstants.reportStatusPending &&
                status.value != AppConstants.reportStatusVerified) {
              status.value = AppConstants.reportStatusDraft;
              isReadOnly.value = false;
              _loadTasks();
            }
          },
        );
  }

  /// Fetch sekali dokumen harian by ID untuk menampilkan status segera
  Future<void> _fetchExistingReportOnce() async {
    try {
      final doc = await _firestore.getDailyReportById(reportId);
      _hasFetchedOnce.value = true;
      if (doc != null) {
        tasks.assignAll(doc.tasks);
        area = doc.areaTugas;
        status.value = doc.status;
        photoUrl.value = doc.photoUrl ?? '';
        isReadOnly.value =
            doc.status == AppConstants.reportStatusPending ||
            doc.status == AppConstants.reportStatusVerified;
        Logger.info(
          'Loaded existing report (fetch once): status=${doc.status}, isReadOnly=$isReadOnly, photoUrl=${doc.photoUrl}',
        );
      } else {
        // Tidak ada dokumen, load tasks baru
        status.value = AppConstants.reportStatusDraft;
        isReadOnly.value = false;
        await _loadTasks();
      }
    } catch (e) {
      Logger.error('Error fetch existing report once', e);
      _hasFetchedOnce.value = true;
      status.value = AppConstants.reportStatusDraft;
      isReadOnly.value = false;
      await _loadTasks();
    }
  }

  Future<void> toggleDone(int index) async {
    if (isReadOnly.value) return;
    final current = tasks[index];
    if (!current.isDone) {
      final selected = await ExecutorBottomSheet.pick(members: members);
      if (selected == null || selected.isEmpty) return;
      tasks[index] = current.copyWith(isDone: true, executors: selected);
    } else {
      tasks[index] = current.copyWith(isDone: false, executors: []);
    }

    // Auto-save sebagai draft setelah perubahan checklist
    await _autoSaveDraft();
  }

  /// Validate before submit
  bool _validateSubmission() {
    final doneTasks = tasks.where((t) => t.isDone).toList();
    if (doneTasks.isEmpty) {
      SnackbarHelper.showWarning('Minimal 1 task harus dikerjakan');
      return false;
    }

    // Check if all done tasks have executor
    final tasksWithoutExecutor = doneTasks
        .where((t) => t.executors.isEmpty)
        .toList();
    if (tasksWithoutExecutor.isNotEmpty) {
      SnackbarHelper.showWarning(
        'Semua task yang dikerjakan harus memiliki minimal 1 executor',
      );
      return false;
    }

    return true;
  }

  Future<void> submit() async {
    if (isReadOnly.value) {
      SnackbarHelper.showInfo('Laporan sudah dikirim, menunggu validasi admin');
      return;
    }

    // Validation
    if (!_validateSubmission()) {
      return;
    }

    isSubmitting.value = true;
    try {
      Logger.debug('Submitting report for kelompok $kelompokId on $date');
      final report = DailyReportModel(
        id: reportId,
        date: date,
        kelompokId: kelompokId,
        areaTugas: area,
        status: AppConstants.reportStatusPending,
        tasks: tasks.toList(),
        photoUrl: photoUrl.value.isEmpty ? null : photoUrl.value,
      );
      await _firestore.saveDailyReport(report);
      Logger.info('Report submitted successfully: $reportId');

      // Kirim push notification ke admin
      await _notificationService.sendNotificationToAdmin(
        title: 'Laporan Baru',
        body: 'Laporan baru dari Kelompok $kelompokId menunggu validasi',
        data: {'type': 'new_report', 'kelompokId': kelompokId.toString()},
      );

      // Set isReadOnly dan status langsung setelah save untuk mencegah edit
      isReadOnly.value = true;
      status.value = AppConstants.reportStatusPending;

      SnackbarHelper.showSuccess('Laporan tersimpan');

      // Tunggu sedikit untuk memastikan Firestore sudah selesai menyimpan
      await Future.delayed(const Duration(milliseconds: 500));

      // Navigate kembali ke dashboard dengan status pending
      // Gunakan arguments agar dashboard langsung tampilkan status pending
      Logger.info(
        'Navigating to dashboard with status: ${AppConstants.reportStatusPending}',
      );
      Get.offAllNamed(
        AppRoutes.santriDashboard,
        arguments: {'reportStatus': AppConstants.reportStatusPending},
      );
    } catch (e) {
      Logger.error('Error submitting report', e);
      SnackbarHelper.showError(ErrorHandler.getErrorMessage(e));
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Auto-save laporan sebagai draft setiap ada perubahan checklist
  Future<void> _autoSaveDraft() async {
    try {
      final draft = DailyReportModel(
        id: reportId,
        date: date,
        kelompokId: kelompokId,
        areaTugas: area,
        status: AppConstants.reportStatusDraft,
        tasks: tasks.toList(),
        photoUrl: photoUrl.value.isEmpty ? null : photoUrl.value,
      );
      await _firestore.saveDailyReport(draft);
      Logger.info('Auto-saved draft report: $reportId');
    } catch (e) {
      Logger.error('Failed to auto-save draft', e);
    }
  }

  /// Pick photo from camera
  Future<void> pickPhotoFromCamera() async {
    if (isReadOnly.value) return;
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );
      if (pickedFile != null) {
        await _processAndUploadPhoto(File(pickedFile.path));
      }
    } catch (e) {
      Logger.error('Error picking photo from camera', e);
      SnackbarHelper.showError('Gagal mengambil foto dari kamera');
    }
  }

  /// Pick photo from gallery
  Future<void> pickPhotoFromGallery() async {
    if (isReadOnly.value) return;
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      if (pickedFile != null) {
        await _processAndUploadPhoto(File(pickedFile.path));
      }
    } catch (e) {
      Logger.error('Error picking photo from gallery', e);
      SnackbarHelper.showError('Gagal memilih foto dari galeri');
    }
  }

  /// Compress image
  Future<File?> compressImage(File file) async {
    try {
      final filePath = file.absolute.path;
      final lastIndex = filePath.lastIndexOf(RegExp(r'\.'));
      final splitted = filePath.substring(0, lastIndex);
      final outPath = '${splitted}_compressed.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        filePath,
        outPath,
        minWidth: 1920,
        minHeight: 1080,
        quality: 85,
        format: CompressFormat.jpeg,
      );

      if (result != null) {
        final originalSize = await file.length();
        final compressedSize = await result.length();
        Logger.info('Image compressed: $originalSize -> $compressedSize bytes');
        return File(result.path);
      }
      return null;
    } catch (e) {
      Logger.error('Error compressing image', e);
      return null;
    }
  }

  /// Process and upload photo
  Future<void> _processAndUploadPhoto(File file) async {
    isUploadingPhoto.value = true;
    try {
      // Compress image first
      final compressedFile = await compressImage(file);
      if (compressedFile == null) {
        SnackbarHelper.showError('Gagal mengompres foto');
        return;
      }

      // Get current user
      final authService = AuthService.instance;
      final user = authService.currentUser;
      if (user == null) {
        SnackbarHelper.showError('User tidak terautentikasi');
        return;
      }

      // Upload to storage
      final uploadedUrl = await _firestore.uploadPhotoToStorage(
        reportId,
        compressedFile,
        kelompokId,
        date,
        user.uid,
      );

      // Update photoUrl
      photoUrl.value = uploadedUrl;

      // Auto-save draft with photo
      await _autoSaveDraft();

      SnackbarHelper.showSuccess('Foto berhasil diunggah');
    } catch (e) {
      Logger.error('Error uploading photo', e);
      SnackbarHelper.showError(
        'Gagal mengunggah foto: ${ErrorHandler.getErrorMessage(e)}',
      );
    } finally {
      isUploadingPhoto.value = false;
    }
  }

  /// Delete photo
  Future<void> deletePhoto() async {
    if (isReadOnly.value) return;
    if (photoUrl.value.isEmpty) return;

    try {
      // Delete from storage
      await _firestore.deletePhotoFromStorage(photoUrl.value);

      // Clear photoUrl
      photoUrl.value = '';

      // Auto-save draft without photo
      await _autoSaveDraft();

      SnackbarHelper.showSuccess('Foto berhasil dihapus');
    } catch (e) {
      Logger.error('Error deleting photo', e);
      SnackbarHelper.showError('Gagal menghapus foto');
    }
  }
}
