import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/logger.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/notification_reminder_model.dart';
import 'auth_service.dart';
import 'fcm_service.dart';
import 'firestore_service.dart';
import 'local_notification_service.dart';
import 'notification_reminder_service.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _fcmService = FCMService.instance;
  final _localNotificationService = LocalNotificationService.instance;
  final _firestore = FirestoreService.instance;
  final _authService = AuthService.instance;
  final _reminderService = NotificationReminderService.instance;

  bool _initialized = false;

  /// Initialize all notification services
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize FCM
      await _fcmService.initialize();

      // Initialize local notifications
      await _localNotificationService.initialize();
      await _localNotificationService.requestPermissions();

      // Schedule all reminders
      await _scheduleAllReminders();

      _initialized = true;
      Logger.info('Notification services initialized');
    } catch (e) {
      Logger.error('Error initializing notification services', e);
    }
  }

  /// Schedule all local notification reminders based on Firestore settings
  Future<void> _scheduleAllReminders() async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        Logger.warning('User not logged in, cannot schedule reminders');
        return;
      }

      final profile = await _firestore.fetchUser(user.uid);
      if (profile == null) {
        Logger.warning('User profile not found, cannot schedule reminders');
        return;
      }

      // Load reminder settings from Firestore
      final reminders = await _reminderService.getReminderSettings(user.uid);

      // If no reminders exist, create defaults
      if (reminders.isEmpty) {
        Logger.info('No reminder settings found, creating defaults...');
        await _reminderService.createDefaultReminders(
          user.uid,
          profile.kelompokId,
        );
        // Reload after creating defaults
        final newReminders = await _reminderService.getReminderSettings(
          user.uid,
        );
        await _scheduleRemindersFromSettings(newReminders, profile.kelompokId);
        return;
      }

      // Schedule reminders based on settings
      await _scheduleRemindersFromSettings(reminders, profile.kelompokId);

      Logger.info(
        'Scheduled ${reminders.length} reminders from Firestore settings',
      );
    } catch (e) {
      Logger.error('Error scheduling reminders', e);
    }
  }

  /// Schedule reminders from Firestore settings
  Future<void> _scheduleRemindersFromSettings(
    List<NotificationReminderModel> reminders,
    int? kelompokId,
  ) async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      for (final reminder in reminders) {
        if (!reminder.enabled) {
          // Cancel reminder if disabled
          await _localNotificationService.cancelReminder(
            reminder.notificationId,
          );
          continue;
        }

        // Schedule based on type
        switch (reminder.type) {
          case 'daily_report':
            if (kelompokId != null) {
              await _localNotificationService.scheduleDailyReportReminder(
                kelompokId: kelompokId,
                time: reminder.time,
              );
            }
            break;
          case 'sholat_dhuha':
            await _localNotificationService.scheduleSholatDhuhaReminder(
              userId: user.uid,
              time: reminder.time,
            );
            break;
          case 'al_mulk':
            await _localNotificationService.scheduleAlMulkReminder(
              userId: user.uid,
              time: reminder.time,
            );
            break;
        }
      }
    } catch (e) {
      Logger.error('Error scheduling reminders from settings', e);
    }
  }

  /// Re-schedule all reminders (call this when reminder settings are updated)
  Future<void> rescheduleAllReminders() async {
    await _scheduleAllReminders();
  }

  /// Send push notification to all coordinators
  /// Note: Untuk push notifications yang benar-benar push (saat app closed),
  /// perlu menggunakan Cloud Functions. Untuk sekarang, kita simpan ke Firestore
  /// dan client-side akan listen untuk menampilkan local notification.
  Future<void> sendNotificationToAllCoordinators({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Simpan notifikasi ke Firestore untuk di-broadcast ke semua koordinator
      // Client-side akan listen dan menampilkan local notification
      final notificationData = {
        'title': title,
        'body': body,
        'type': data?['type'] ?? 'general',
        'data': data ?? {},
        'target': 'all_coordinators',
        'created_at': FieldValue.serverTimestamp(),
        'read': false,
      };

      // Simpan ke collection notifications
      final db = FirebaseFirestore.instance;
      await db.collection('notifications').add(notificationData);

      // Tampilkan local notification sebagai fallback (jika app terbuka)
      await showLocalNotification(title: title, body: body, data: data);

      Logger.info(
        'Notification saved to Firestore for all coordinators: $title',
      );
    } catch (e) {
      Logger.error('Error sending notification to coordinators', e);
    }
  }

  /// Send push notification to admin
  Future<void> sendNotificationToAdmin({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Simpan notifikasi ke Firestore untuk admin
      final notificationData = {
        'title': title,
        'body': body,
        'type': data?['type'] ?? 'general',
        'data': data ?? {},
        'target': 'admin',
        'created_at': FieldValue.serverTimestamp(),
        'read': false,
      };

      // Simpan ke collection notifications
      final db = FirebaseFirestore.instance;
      await db.collection('notifications').add(notificationData);

      // Tampilkan local notification sebagai fallback (jika app terbuka)
      await showLocalNotification(title: title, body: body, data: data);

      Logger.info('Notification saved to Firestore for admin: $title');
    } catch (e) {
      Logger.error('Error sending notification to admin', e);
    }
  }

  /// Show local notification (for foreground messages)
  Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // This will be handled by FCM foreground message handler
    // or we can use snackbar for now
    SnackbarHelper.showInfo(body, title: title);
  }

  /// Test local notification (for debugging)
  Future<void> testLocalNotification() async {
    try {
      Logger.info('Testing local notification...');
      await _localNotificationService.showTestNotification();
      SnackbarHelper.showSuccess('Test notification sent');
    } catch (e) {
      Logger.error('Error testing local notification', e);
      SnackbarHelper.showError('Gagal mengirim test notification');
    }
  }

  /// Get notification permission status (for debugging)
  Future<Map<String, dynamic>> getPermissionStatus() async {
    try {
      return await _localNotificationService.getPermissionStatus();
    } catch (e) {
      Logger.error('Error getting permission status', e);
      return {'error': e.toString()};
    }
  }
}
