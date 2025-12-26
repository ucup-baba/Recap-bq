import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/notification_reminder_model.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firestore_service.dart';
import '../../data/services/local_notification_service.dart';
import '../../data/services/notification_reminder_service.dart';
import '../../data/services/notification_service.dart';

class NotificationSettingsController extends GetxController {
  final _reminderService = NotificationReminderService.instance;
  final _localNotificationService = LocalNotificationService.instance;
  final _notificationService = NotificationService.instance;
  final _authService = AuthService.instance;
  final _firestore = FirestoreService.instance;

  final reminders = <NotificationReminderModel>[].obs;
  final allReminders = <NotificationReminderModel>[].obs; // All reminders for Super Admin
  final allUsers = <UserModel>[].obs; // All users for Super Admin
  final selectedUserId = Rxn<String>(); // Selected user filter (null = all users)
  final isLoading = false.obs;
  final scheduledNotifications = <PendingNotificationRequest>[].obs;
  final isSuperAdmin = false.obs;

  @override
  void onInit() {
    super.onInit();
    _checkRole();
    loadReminders();
    loadScheduledNotifications();
  }

  /// Check if current user is Super Admin
  void _checkRole() {
    final user = _authService.currentUser;
    if (user == null) {
      Logger.warning('User not logged in');
      return;
    }
    
    _firestore.fetchUser(user.uid).then((profile) {
      if (profile != null) {
        isSuperAdmin.value = profile.role == AppConstants.userRoleSuperAdmin;
        if (!isSuperAdmin.value) {
          Logger.warning('User is not Super Admin, redirecting...');
          Get.back();
          SnackbarHelper.showError('Hanya Super Admin yang dapat mengakses halaman ini');
        }
      }
    }).catchError((e) {
      Logger.error('Error checking role', e);
      Get.back();
      SnackbarHelper.showError('Gagal memverifikasi akses');
    });
  }

  /// Load all reminder settings (for Super Admin: all users, for others: own reminders)
  Future<void> loadReminders() async {
    isLoading.value = true;
    try {
      if (!isSuperAdmin.value) {
        // For non-super admin, load only own reminders (backward compatibility)
        final user = _authService.currentUser;
        if (user == null) {
          Logger.warning('User not logged in, cannot load reminders');
          return;
        }

        final profile = await _firestore.fetchUser(user.uid);
        if (profile == null) {
          Logger.warning('User profile not found');
          return;
        }

        // Get existing reminders
        var reminderList = await _reminderService.getReminderSettings(user.uid);

        // If no reminders exist, create defaults
        if (reminderList.isEmpty) {
          await _reminderService.createDefaultReminders(
            user.uid,
            profile.kelompokId,
          );
          reminderList = await _reminderService.getReminderSettings(user.uid);
        }

        reminders.value = reminderList;
        Logger.info('Loaded ${reminderList.length} reminder settings');
        return;
      }

      // For Super Admin: Load all reminders and all users
      await loadAllUsers();
      final allReminderList = await _reminderService.getAllReminderSettings();
      allReminders.value = allReminderList;
      
      // Filter reminders based on selectedUserId
      _updateFilteredReminders();
      
      Logger.info('Loaded ${allReminderList.length} reminder settings for all users');
    } catch (e) {
      Logger.error('Error loading reminders', e);
      SnackbarHelper.showError('Gagal memuat pengaturan reminder');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load all users (for Super Admin)
  Future<void> loadAllUsers() async {
    try {
      final users = await _firestore.getAllUsers();
      allUsers.value = users;
      Logger.info('Loaded ${users.length} users');
    } catch (e) {
      Logger.error('Error loading all users', e);
    }
  }

  /// Update filtered reminders based on selectedUserId
  void _updateFilteredReminders() {
    if (selectedUserId.value == null) {
      // Show all reminders
      reminders.value = allReminders.toList();
    } else {
      // Filter by selected user
      reminders.value = allReminders
          .where((r) => r.userId == selectedUserId.value)
          .toList();
    }
  }

  /// Select user to filter reminders
  void selectUser(String? userId) {
    selectedUserId.value = userId;
    _updateFilteredReminders();
  }

  /// Get user display name by userId
  String? getUserDisplayName(String userId) {
    try {
      final user = allUsers.firstWhere((u) => u.uid == userId);
      return user.displayName;
    } catch (e) {
      return null;
    }
  }

  /// Load scheduled notifications
  Future<void> loadScheduledNotifications() async {
    try {
      final scheduled = await _localNotificationService.getScheduledReminders();
      scheduledNotifications.value = scheduled;
      Logger.info('Loaded ${scheduled.length} scheduled notifications');
    } catch (e) {
      Logger.error('Error loading scheduled notifications', e);
    }
  }

  /// Toggle enable/disable reminder
  Future<void> toggleReminder(NotificationReminderModel reminder) async {
    try {
      final updated = reminder.copyWith(
        enabled: !reminder.enabled,
        updatedAt: DateTime.now(),
      );

      await _reminderService.enableReminder(reminder.id, updated.enabled);
      
      // Update local lists
      final index = reminders.indexWhere((r) => r.id == reminder.id);
      if (index != -1) {
        reminders[index] = updated;
      }
      
      final allIndex = allReminders.indexWhere((r) => r.id == reminder.id);
      if (allIndex != -1) {
        allReminders[allIndex] = updated;
      }

      // Update schedule for the specific user
      if (updated.enabled) {
        await _localNotificationService.updateReminderSchedule(
          type: updated.type,
          enabled: updated.enabled,
          time: updated.time,
          userId: updated.userId,
          kelompokId: updated.kelompokId,
        );
      } else {
        await _localNotificationService.cancelReminder(updated.notificationId);
      }

      final userName = getUserDisplayName(reminder.userId) ?? 'User';
      SnackbarHelper.showSuccess(
        'Reminder ${updated.enabled ? 'diaktifkan' : 'dinonaktifkan'} untuk $userName',
      );
      
      // Reload scheduled notifications
      await loadScheduledNotifications();
    } catch (e) {
      Logger.error('Error toggling reminder', e);
      SnackbarHelper.showError('Gagal mengubah status reminder');
    }
  }

  /// Update reminder time
  Future<void> updateReminderTime(
    NotificationReminderModel reminder,
    TimeOfDay newTime,
  ) async {
    try {
      final updated = reminder.copyWith(
        time: newTime,
        updatedAt: DateTime.now(),
      );

      await _reminderService.updateReminderTime(reminder.id, newTime);
      
      // Update local lists
      final index = reminders.indexWhere((r) => r.id == reminder.id);
      if (index != -1) {
        reminders[index] = updated;
      }
      
      final allIndex = allReminders.indexWhere((r) => r.id == reminder.id);
      if (allIndex != -1) {
        allReminders[allIndex] = updated;
      }

      // Update schedule if enabled
      if (updated.enabled) {
        await _localNotificationService.updateReminderSchedule(
          type: updated.type,
          enabled: updated.enabled,
          time: updated.time,
          userId: updated.userId,
          kelompokId: updated.kelompokId,
        );
      }

      final userName = getUserDisplayName(reminder.userId) ?? 'User';
      SnackbarHelper.showSuccess('Waktu reminder diupdate untuk $userName');
      
      // Reload scheduled notifications
      await loadScheduledNotifications();
    } catch (e) {
      Logger.error('Error updating reminder time', e);
      SnackbarHelper.showError('Gagal mengupdate waktu reminder');
    }
  }

  /// Delete reminder
  Future<void> deleteReminder(NotificationReminderModel reminder) async {
    try {
      // Show confirmation dialog
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Hapus Reminder'),
          content: Text('Yakin ingin menghapus reminder ${reminder.displayName}?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Cancel notification
      await _localNotificationService.cancelReminder(reminder.notificationId);
      
      // Delete from Firestore
      await _reminderService.deleteReminderSetting(reminder.id);
      
      // Remove from local lists
      reminders.removeWhere((r) => r.id == reminder.id);
      allReminders.removeWhere((r) => r.id == reminder.id);

      final userName = getUserDisplayName(reminder.userId) ?? 'User';
      SnackbarHelper.showSuccess('Reminder dihapus untuk $userName');
      
      // Reload scheduled notifications
      await loadScheduledNotifications();
    } catch (e) {
      Logger.error('Error deleting reminder', e);
      SnackbarHelper.showError('Gagal menghapus reminder');
    }
  }

  /// Test notification
  Future<void> testNotification(NotificationReminderModel reminder) async {
    try {
      await _notificationService.testLocalNotification();
    } catch (e) {
      Logger.error('Error testing notification', e);
      SnackbarHelper.showError('Gagal mengirim test notification');
    }
  }

  /// Show time picker and update reminder time
  Future<void> openTimePicker(NotificationReminderModel reminder) async {
    try {
      final context = Get.context;
      if (context == null) {
        Logger.warning('Context is null, cannot show time picker');
        return;
      }

      final pickedTime = await showTimePicker(
        context: context,
        initialTime: reminder.time,
        helpText: 'Pilih Waktu Reminder',
      );

      if (pickedTime != null && pickedTime != reminder.time) {
        await updateReminderTime(reminder, pickedTime);
      }
    } catch (e) {
      Logger.error('Error showing time picker', e);
    }
  }

  /// Cancel scheduled notification
  Future<void> cancelScheduledNotification(int notificationId) async {
    try {
      await _localNotificationService.cancelReminder(notificationId);
      await loadScheduledNotifications();
      SnackbarHelper.showSuccess('Notification dibatalkan');
    } catch (e) {
      Logger.error('Error cancelling scheduled notification', e);
      SnackbarHelper.showError('Gagal membatalkan notification');
    }
  }
}

