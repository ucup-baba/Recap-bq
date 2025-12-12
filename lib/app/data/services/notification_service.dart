import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/logger.dart';
import '../../core/utils/snackbar_helper.dart';
import 'auth_service.dart';
import 'fcm_service.dart';
import 'firestore_service.dart';
import 'local_notification_service.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _fcmService = FCMService.instance;
  final _localNotificationService = LocalNotificationService.instance;
  final _firestore = FirestoreService.instance;
  final _authService = AuthService.instance;

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

  /// Schedule all local notification reminders
  Future<void> _scheduleAllReminders() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final profile = await _firestore.fetchUser(user.uid);
      if (profile == null) return;

      // Schedule daily report reminder (07:00)
      if (profile.kelompokId != null) {
        await _localNotificationService.scheduleDailyReportReminder(
          kelompokId: profile.kelompokId!,
        );
      }

      // Schedule sholat dhuha reminder (09:00) - hanya untuk koordinator
      if (profile.role == 'koordinator') {
        await _localNotificationService.scheduleSholatDhuhaReminder(
          userId: user.uid,
        );
        await _localNotificationService.scheduleAlMulkReminder(
          userId: user.uid,
        );
      }
    } catch (e) {
      Logger.error('Error scheduling reminders', e);
    }
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

      Logger.info('Notification saved to Firestore for all coordinators: $title');
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
}
