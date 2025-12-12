import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
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
import '../../data/models/user_model.dart';
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
  String get reportId {
    if (kelompokId <= 0) {
      Logger.error('Invalid kelompokId: $kelompokId');
      return '';
    }
    if (date.isEmpty) {
      Logger.error('Invalid date: empty');
      return '';
    }
    return '$kelompokId-$date';
  }

  StreamSubscription<List<DailyReportModel>>? _reportSubscription;
  StreamSubscription? _userSubscription;
  Timer? _kelompokIdTimeout;
  bool _hasReceivedFirstProfile = false;
  bool _isAutoFixingKelompokId = false;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    area = args['area'] ?? '';
    // Handle kelompokId - bisa int atau null
    final kelompokIdArg = args['kelompokId'];
    if (kelompokIdArg is int) {
      kelompokId = kelompokIdArg;
    } else if (kelompokIdArg is num) {
      kelompokId = kelompokIdArg.toInt();
    } else {
      kelompokId = 0;
    }
    date = args['date'] ?? AppDateUtils.formatDate(DateTime.now());

    // Fallback: jika area kosong, hitung dari kelompokId dan date
    if (area.isEmpty && kelompokId > 0) {
      final dateTime = date.isNotEmpty ? DateTime.parse(date) : DateTime.now();
      area = _rotation.getAreaForGroup(kelompokId, dateTime);
      Logger.info(
        'Area calculated from kelompokId: $area for kelompok $kelompokId on $date',
      );
    }

    // Jika kelompokId masih 0, gunakan watchUser stream untuk menunggu
    if (kelompokId <= 0) {
      _waitForKelompokIdFromStream();
      return;
    }

    // Validasi input
    if (kelompokId <= 0) {
      _handleInvalidKelompokId();
      return;
    }

    _initializeReportInput();
  }

  void _waitForKelompokIdFromStream() {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      Logger.error('No authenticated user');
      _handleInvalidKelompokId();
      return;
    }

    Logger.info('Waiting for kelompokId from user stream...');

    // Set timeout 5 detik
    _kelompokIdTimeout = Timer(const Duration(seconds: 5), () {
      if (kelompokId <= 0) {
        Logger.error('Timeout waiting for kelompokId');
        _userSubscription?.cancel();
        _handleInvalidKelompokId();
      }
    });

    // Coba fetch sekali dulu untuk cek apakah user memang tidak punya kelompokId
    _firestore
        .fetchUser(user.uid)
        .then((profile) async {
          if (profile == null) {
            Logger.warning('User profile is null from fetch');
            return;
          }

          // Cek jika user adalah admin - admin tidak perlu kelompokId
          if (profile.role == 'admin') {
            Logger.warning(
              'Admin user trying to access report input - redirecting to admin dashboard',
            );
            _kelompokIdTimeout?.cancel();
            _userSubscription?.cancel();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Future.delayed(const Duration(milliseconds: 200), () {
                SnackbarHelper.showError(
                  'Admin tidak dapat mengakses halaman input laporan',
                );
                Get.offAllNamed('/admin-dashboard');
              });
            });
            return;
          }

          // Jika user sudah punya kelompokId, langsung gunakan
          if (profile.kelompokId != null && profile.kelompokId! > 0) {
            _kelompokIdTimeout?.cancel();
            _userSubscription?.cancel();

            kelompokId = profile.kelompokId!;
            Logger.info('Loaded kelompokId from initial fetch: $kelompokId');

            // Hitung area jika masih kosong
            if (area.isEmpty) {
              final dateTime = date.isNotEmpty
                  ? DateTime.parse(date)
                  : DateTime.now();
              area = _rotation.getAreaForGroup(kelompokId, dateTime);
              Logger.info('Area calculated from kelompokId: $area');
            }

            _initializeReportInput();
            return;
          }

          // Jika user tidak punya kelompokId, coba auto-fix dari email
          if (profile.role == 'koordinator' && profile.kelompokId == null) {
            Logger.warning(
              'User profile has no kelompokId: ${profile.uid}, role: ${profile.role}, email: ${profile.email}',
            );

            // Coba extract kelompokId dari email (ketuakel1@bqmail.com -> 1)
            final extractedKelompokId = _extractKelompokIdFromEmail(
              profile.email,
            );

            if (extractedKelompokId != null && extractedKelompokId > 0) {
              Logger.info(
                'Auto-fixing kelompokId from email: $extractedKelompokId for user ${profile.uid}',
              );

              // Set flag untuk skip validasi di stream listener
              _isAutoFixingKelompokId = true;

              // Cancel stream subscription SEBELUM update untuk menghindari race condition
              _userSubscription?.cancel();
              _kelompokIdTimeout?.cancel();

              // Update kelompokId di Firestore
              try {
                await _firestore.updateUserKelompokId(
                  profile.uid,
                  extractedKelompokId,
                );
                Logger.info('Successfully updated kelompokId in Firestore');

                // Set kelompokId dan lanjutkan
                kelompokId = extractedKelompokId;

                // Hitung area jika masih kosong
                if (area.isEmpty) {
                  final dateTime = date.isNotEmpty
                      ? DateTime.parse(date)
                      : DateTime.now();
                  area = _rotation.getAreaForGroup(kelompokId, dateTime);
                  Logger.info('Area calculated from kelompokId: $area');
                }

                // Reset flag
                _isAutoFixingKelompokId = false;

                _initializeReportInput();
                return;
              } catch (e) {
                Logger.error('Error updating kelompokId in Firestore', e);
                _isAutoFixingKelompokId = false;
                // Fall through to reject
              }
            }
          }

          // Jika tidak bisa auto-fix, reject dengan pesan jelas
          _kelompokIdTimeout?.cancel();
          // Cancel stream subscription yang mungkin sudah dibuat
          _userSubscription?.cancel();
          _handleInvalidKelompokIdWithProfile(profile);
        })
        .catchError((e) {
          Logger.error('Error fetching user profile initially', e);
          // Jika fetch gagal, lanjutkan dengan stream sebagai fallback
          // Stream subscription akan dibuat di bawah
        });

    // Subscribe ke watchUser stream sebagai fallback atau untuk update real-time
    _userSubscription = _firestore
        .watchUser(user.uid)
        .listen(
          (profile) {
            if (profile == null) {
              Logger.warning('User profile is null in stream');
              return;
            }

            // Skip validasi jika sedang dalam proses auto-fix
            if (_isAutoFixingKelompokId) {
              Logger.info('Skipping stream validation - auto-fix in progress');
              return;
            }

            // Track emit pertama
            if (!_hasReceivedFirstProfile) {
              _hasReceivedFirstProfile = true;

              // Cek jika user adalah admin - admin tidak perlu kelompokId
              if (profile.role == 'admin') {
                Logger.warning(
                  'Admin user trying to access report input - redirecting to admin dashboard',
                );
                _kelompokIdTimeout?.cancel();
                _userSubscription?.cancel();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Future.delayed(const Duration(milliseconds: 200), () {
                    SnackbarHelper.showError(
                      'Admin tidak dapat mengakses halaman input laporan',
                    );
                    Get.offAllNamed('/admin-dashboard');
                  });
                });
                return;
              }

              // Jika emit pertama tidak punya kelompokId, tunggu sebentar untuk auto-fix
              if (profile.kelompokId == null || profile.kelompokId! <= 0) {
                Logger.warning(
                  'User profile has no kelompokId on first emit: ${profile.uid}, role: ${profile.role}. '
                  'Waiting for auto-fix or timeout...',
                );
                // Jangan langsung reject, biarkan timeout atau auto-fix handle
                return;
              }
            }

            if (profile.kelompokId != null && profile.kelompokId! > 0) {
              // Cancel timeout karena sudah dapat kelompokId
              _kelompokIdTimeout?.cancel();
              _userSubscription?.cancel();

              kelompokId = profile.kelompokId!;
              Logger.info('Loaded kelompokId from user stream: $kelompokId');

              // Hitung area jika masih kosong
              if (area.isEmpty) {
                final dateTime = date.isNotEmpty
                    ? DateTime.parse(date)
                    : DateTime.now();
                area = _rotation.getAreaForGroup(kelompokId, dateTime);
                Logger.info('Area calculated from kelompokId: $area');
              }

              _initializeReportInput();
            }
          },
          onError: (error) {
            Logger.error('Error in watchUser stream', error);
            _kelompokIdTimeout?.cancel();
            _userSubscription?.cancel();
            _handleInvalidKelompokId();
          },
        );
  }

  /// Extract kelompokId from email pattern (ketuakel1@bqmail.com -> 1)
  int? _extractKelompokIdFromEmail(String email) {
    try {
      // Pattern: ketuakel1@bqmail.com, ketuakel2@bqmail.com, etc.
      final regex = RegExp(r'ketuakel(\d+)@');
      final match = regex.firstMatch(email.toLowerCase());
      if (match != null && match.groupCount >= 1) {
        final idStr = match.group(1);
        if (idStr != null) {
          final id = int.tryParse(idStr);
          if (id != null && id >= 1 && id <= 5) {
            return id;
          }
        }
      }
    } catch (e) {
      Logger.error('Error extracting kelompokId from email: $email', e);
    }
    return null;
  }

  void _initializeReportInput() {
    if (date.isEmpty) {
      Logger.warning('Date is empty, using today');
      date = AppDateUtils.formatDate(DateTime.now());
    }

    if (area.isEmpty) {
      Logger.warning('Area is empty');
    }

    // Load tasks dulu untuk immediate feedback, baru load report dan members
    _loadTasks();

    // Load members dan existing report secara parallel
    _loadMembers();
    _loadExistingReport();
  }

  void _handleInvalidKelompokIdWithProfile(UserModel profile) {
    Logger.error(
      'Invalid kelompokId for user: ${profile.uid}, role: ${profile.role}, kelompokId: ${profile.kelompokId}',
    );

    String errorMessage = 'Kelompok ID tidak valid';
    if (profile.role == 'admin') {
      errorMessage = 'Admin tidak dapat mengakses halaman input laporan';
    } else if (profile.kelompokId == null) {
      errorMessage =
          'Anda belum di-assign ke kelompok. Silakan hubungi admin untuk menambahkan Anda ke kelompok.';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        SnackbarHelper.showError(errorMessage);
        Get.back();
      });
    });
  }

  void _handleInvalidKelompokId() async {
    Logger.error('Invalid kelompokId: $kelompokId, returning to dashboard');

    // Cek role user untuk memberikan pesan error yang lebih spesifik
    final user = AuthService.instance.currentUser;
    String errorMessage = 'Kelompok ID tidak valid';

    if (user != null) {
      try {
        final profile = await _firestore.fetchUser(user.uid);
        if (profile != null) {
          _handleInvalidKelompokIdWithProfile(profile);
          return;
        }
      } catch (e) {
        Logger.error('Error fetching user profile for error message', e);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        SnackbarHelper.showError(errorMessage);
        Get.back();
      });
    });
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
    _userSubscription?.cancel();
    _kelompokIdTimeout?.cancel();
    super.onClose();
  }

  Future<void> _loadExistingReport() async {
    _reportSubscription?.cancel();
    _hasFetchedOnce.value = false;

    // Fetch sekali dokumen langsung by ID untuk tampilkan status segera
    // Jangan await - biarkan stream yang handle untuk tidak blocking UI
    _fetchExistingReportOnce();

    // Tetap dengarkan stream untuk update real-time (verified/rejected/reset oleh admin)
    _reportSubscription = _firestore
        .reportsByGroupAndDate(kelompokId, date)
        .listen(
          (existing) {
            _hasFetchedOnce.value = true;
            if (existing.isNotEmpty) {
              final report = existing.first;
              // Set area dulu sebelum load tasks
              area = report.areaTugas;
              status.value = report.status;
              photoUrl.value = report.photoUrl ?? '';

              // Pastikan tasks ter-load, bahkan jika laporan sudah verified
              if (report.tasks.isNotEmpty) {
                tasks.assignAll(report.tasks);
              } else {
                // Jika tasks kosong, load tasks dari area (untuk display)
                Logger.warning(
                  'Report exists but tasks are empty, loading tasks from area: $area',
                );
                _loadTasks();
              }

              // Lock when pending/verified; allow edit/resubmit if rejected/draft.
              isReadOnly.value =
                  report.status == AppConstants.reportStatusPending ||
                  report.status == AppConstants.reportStatusVerified;
              Logger.info(
                'Loaded existing report (stream): status=${report.status}, isReadOnly=$isReadOnly, photoUrl=${report.photoUrl}, tasksCount=${tasks.length}, area=$area',
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
      // Validasi reportId sebelum fetch
      if (reportId.isEmpty) {
        Logger.error(
          'Cannot fetch report: reportId is empty (kelompokId=$kelompokId, date=$date)',
        );
        _hasFetchedOnce.value = true;
        status.value = AppConstants.reportStatusDraft;
        isReadOnly.value = false;
        await _loadTasks();
        return;
      }

      final doc = await _firestore.getDailyReportById(reportId);
      _hasFetchedOnce.value = true;
      if (doc != null) {
        // Set area dulu sebelum load tasks
        area = doc.areaTugas;
        status.value = doc.status;
        photoUrl.value = doc.photoUrl ?? '';

        // Pastikan tasks ter-load, bahkan jika laporan sudah verified
        if (doc.tasks.isNotEmpty) {
          tasks.assignAll(doc.tasks);
        } else {
          // Jika tasks kosong, load tasks dari area (untuk display)
          Logger.warning(
            'Report exists but tasks are empty, loading tasks from area: $area',
          );
          await _loadTasks();
          // Tetap set status dan readOnly dari report
        }

        isReadOnly.value =
            doc.status == AppConstants.reportStatusPending ||
            doc.status == AppConstants.reportStatusVerified;
        Logger.info(
          'Loaded existing report (fetch once): status=${doc.status}, isReadOnly=$isReadOnly, photoUrl=${doc.photoUrl}, tasksCount=${tasks.length}, area=$area',
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
