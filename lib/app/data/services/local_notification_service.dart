import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../core/routes/app_pages.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/logger.dart';
import 'auth_service.dart';
import 'firestore_service.dart';

class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final _firestore = FirestoreService.instance;

  bool _initialized = false;

  /// Initialize local notifications
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize timezone
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

      // Android initialization settings
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize plugin
      final initialized = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _handleNotificationTap,
      );

      if (initialized == true) {
        // Create notification channels for Android
        await _createNotificationChannels();
        _initialized = true;
        Logger.info('Local notifications initialized successfully');
        Logger.info('Timezone location: ${tz.local.name}');

        // Check pending notifications for debugging
        try {
          final pending = await _notifications.pendingNotificationRequests();
          Logger.info('Pending notifications: ${pending.length}');
          if (pending.isNotEmpty) {
            for (final notification in pending) {
              Logger.info(
                '  - ID: ${notification.id}, Title: ${notification.title}',
              );
            }
          }
        } catch (e) {
          Logger.warning('Error checking pending notifications: $e');
        }
      } else {
        Logger.warning('Failed to initialize local notifications');
      }
    } catch (e) {
      Logger.error('Error initializing local notifications', e);
    }
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    // Channel for reminders
    const reminderChannel = AndroidNotificationChannel(
      'reminder_channel',
      'Reminder',
      description: 'Reminder untuk mengisi laporan harian',
      importance: Importance.high,
    );

    // Channel for ibadah
    const ibadahChannel = AndroidNotificationChannel(
      'ibadah_channel',
      'Ibadah',
      description: 'Reminder untuk ibadah harian',
      importance: Importance.high,
    );

    // Channel for high importance FCM notifications
    const highImportanceChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(reminderChannel);
    await androidPlugin?.createNotificationChannel(ibadahChannel);
    await androidPlugin?.createNotificationChannel(highImportanceChannel);
  }

  /// Create high importance channel for FCM notifications
  Future<void> createHighImportanceChannel() async {
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(androidChannel);
  }

  /// Show notification from FCM
  Future<void> showFCMNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    int? notificationId,
  }) async {
    await createHighImportanceChannel();

    await _notifications.show(
      notificationId ?? DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription:
              'This channel is used for important notifications',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: data?.toString(),
    );
  }

  /// Request notification permissions with explicit checks
  Future<bool> requestPermissions() async {
    try {
      Logger.info('Requesting notification permissions...');

      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        // Request notification permission (Android 13+)
        final granted = await androidPlugin.requestNotificationsPermission();
        if (granted == true) {
          Logger.info('Notification permission granted');
        } else {
          Logger.warning('Notification permission denied');
        }

        // Check and request exact alarm permission (Android 12+)
        final canScheduleExact = await androidPlugin
            .canScheduleExactNotifications();
        Logger.info('Can schedule exact notifications: $canScheduleExact');

        if (canScheduleExact == false) {
          Logger.info('Requesting exact alarm permission...');
          final exactGranted = await androidPlugin
              .requestExactAlarmsPermission();
          if (exactGranted == true) {
            Logger.info('Exact alarm permission granted');
          } else {
            Logger.warning(
              'Exact alarm permission denied - will use inexact mode',
            );
          }
        }

        return granted ?? false;
      }

      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        if (granted == true) {
          Logger.info('iOS notification permission granted');
        } else {
          Logger.warning('iOS notification permission denied');
        }
        return granted ?? false;
      }

      Logger.warning('No platform-specific notification plugin found');
      return false;
    } catch (e) {
      Logger.error('Error requesting notification permissions', e);
      return false;
    }
  }

  /// Check if exact alarms are permitted (Android 12+)
  Future<bool> _canScheduleExactAlarms() async {
    try {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        return await androidPlugin.canScheduleExactNotifications() ?? false;
      }
      return false;
    } catch (e) {
      Logger.warning('Error checking exact alarm permission: $e');
      return false;
    }
  }

  /// Request exact alarm permission (Android 12+)
  Future<bool> requestExactAlarmPermission() async {
    try {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        return await androidPlugin.requestExactAlarmsPermission() ?? false;
      }
      return false;
    } catch (e) {
      Logger.warning('Error requesting exact alarm permission: $e');
      return false;
    }
  }

  /// Schedule daily reminder untuk mengisi laporan (07:00)
  Future<void> scheduleDailyReportReminder({
    required int kelompokId,
    TimeOfDay? time,
  }) async {
    try {
      final reminderTime = time ?? const TimeOfDay(hour: 7, minute: 0);
      final now = DateTime.now();
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        reminderTime.hour,
        reminderTime.minute,
      );

      // Jika waktu sudah lewat hari ini, schedule untuk besok
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // Cancel existing reminder
      await _notifications.cancel(100);

      // Cek apakah laporan sudah diisi hari ini sebelum schedule
      final hasReport = await hasReportToday(kelompokId);
      if (hasReport) {
        Logger.info('Report already submitted today, skipping reminder');
        return;
      }

      // Cek apakah exact alarms diizinkan, jika tidak gunakan inexact
      final canScheduleExact = await _canScheduleExactAlarms();
      final scheduleMode = canScheduleExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      // Schedule new reminder
      await _notifications.zonedSchedule(
        100,
        'Jangan Lupa Mengisi Laporan',
        'Jangan lupa mengisi laporan harian hari ini',
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'reminder_channel',
            'Reminder',
            channelDescription: 'Reminder untuk mengisi laporan harian',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'daily_report:$kelompokId',
      );

      Logger.info(
        'Daily report reminder scheduled at ${reminderTime.hour.toString().padLeft(2, '0')}:${reminderTime.minute.toString().padLeft(2, '0')} (mode: ${canScheduleExact ? 'exact' : 'inexact'})',
      );
    } catch (e) {
      Logger.error('Error scheduling daily report reminder', e);
      // Jika exact alarm gagal, coba dengan inexact
      final errorString = e.toString();
      if (errorString.contains('exact_alarms_not_permitted')) {
        try {
          Logger.info('Retrying with inexact mode');
          final now = DateTime.now();
          var scheduledDate = tz.TZDateTime(
            tz.local,
            now.year,
            now.month,
            now.day,
            (time ?? const TimeOfDay(hour: 7, minute: 0)).hour,
            (time ?? const TimeOfDay(hour: 7, minute: 0)).minute,
          );
          if (scheduledDate.isBefore(now)) {
            scheduledDate = scheduledDate.add(const Duration(days: 1));
          }
          await _notifications.zonedSchedule(
            100,
            'Jangan Lupa Mengisi Laporan',
            'Jangan lupa mengisi laporan harian hari ini',
            scheduledDate,
            NotificationDetails(
              android: AndroidNotificationDetails(
                'reminder_channel',
                'Reminder',
                channelDescription: 'Reminder untuk mengisi laporan harian',
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
              iOS: const DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
            payload: 'daily_report:$kelompokId',
          );
          Logger.info('Daily report reminder scheduled with inexact mode');
        } catch (retryError) {
          Logger.error('Error retrying with inexact mode', retryError);
        }
      }
    }
  }

  /// Schedule sholat dhuha reminder (09:00)
  Future<void> scheduleSholatDhuhaReminder({
    required String userId,
    TimeOfDay? time,
  }) async {
    try {
      final reminderTime = time ?? const TimeOfDay(hour: 9, minute: 0);
      final now = DateTime.now();
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        reminderTime.hour,
        reminderTime.minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // Cancel existing reminder
      await _notifications.cancel(200);

      // Cek apakah exact alarms diizinkan, jika tidak gunakan inexact
      final canScheduleExact = await _canScheduleExactAlarms();
      final scheduleMode = canScheduleExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      // Schedule new reminder
      await _notifications.zonedSchedule(
        200,
        'Sholat Dhuha',
        'Sudah sholat dhuha belum hari ini?',
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'ibadah_channel',
            'Ibadah',
            channelDescription: 'Reminder untuk ibadah harian',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            actions: [
              const AndroidNotificationAction(
                'ibadah_sudah',
                'V',
                showsUserInterface: true,
              ),
              const AndroidNotificationAction(
                'ibadah_belum',
                'X',
                showsUserInterface: true,
              ),
            ],
            category: AndroidNotificationCategory.message,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'sholat_dhuha',
      );

      Logger.info(
        'Sholat dhuha reminder scheduled at ${reminderTime.hour.toString().padLeft(2, '0')}:${reminderTime.minute.toString().padLeft(2, '0')} (mode: ${canScheduleExact ? 'exact' : 'inexact'})',
      );
    } catch (e) {
      Logger.error('Error scheduling sholat dhuha reminder', e);
      // Jika exact alarm gagal, coba dengan inexact
      final errorString = e.toString();
      if (errorString.contains('exact_alarms_not_permitted')) {
        try {
          Logger.info('Retrying sholat dhuha reminder with inexact mode');
          final now = DateTime.now();
          var scheduledDate = tz.TZDateTime(
            tz.local,
            now.year,
            now.month,
            now.day,
            (time ?? const TimeOfDay(hour: 9, minute: 0)).hour,
            (time ?? const TimeOfDay(hour: 9, minute: 0)).minute,
          );
          if (scheduledDate.isBefore(now)) {
            scheduledDate = scheduledDate.add(const Duration(days: 1));
          }
          await _notifications.zonedSchedule(
            200,
            'Sholat Dhuha',
            'Sudah sholat dhuha belum hari ini?',
            scheduledDate,
            NotificationDetails(
              android: AndroidNotificationDetails(
                'ibadah_channel',
                'Ibadah',
                channelDescription: 'Reminder untuk ibadah harian',
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
                actions: [
                  const AndroidNotificationAction(
                    'ibadah_sudah',
                    'V',
                    showsUserInterface: true,
                  ),
                  const AndroidNotificationAction(
                    'ibadah_belum',
                    'X',
                    showsUserInterface: true,
                  ),
                ],
                category: AndroidNotificationCategory.message,
              ),
              iOS: const DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
            payload: 'sholat_dhuha',
          );
          Logger.info('Sholat dhuha reminder scheduled with inexact mode');
        } catch (retryError) {
          Logger.error('Error retrying with inexact mode', retryError);
        }
      }
    }
  }

  /// Schedule al-mulk reminder (21:30)
  Future<void> scheduleAlMulkReminder({
    required String userId,
    TimeOfDay? time,
  }) async {
    try {
      final reminderTime = time ?? const TimeOfDay(hour: 21, minute: 30);
      final now = DateTime.now();
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        reminderTime.hour,
        reminderTime.minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // Cancel existing reminder
      await _notifications.cancel(300);

      // Cek apakah exact alarms diizinkan, jika tidak gunakan inexact
      final canScheduleExact = await _canScheduleExactAlarms();
      final scheduleMode = canScheduleExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      // Schedule new reminder
      await _notifications.zonedSchedule(
        300,
        'Al-Mulk',
        'Persiapan tidur, sudah baca al-mulk belum?',
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'ibadah_channel',
            'Ibadah',
            channelDescription: 'Reminder untuk ibadah harian',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            actions: [
              const AndroidNotificationAction(
                'ibadah_sudah',
                'V',
                showsUserInterface: true,
              ),
              const AndroidNotificationAction(
                'ibadah_belum',
                'X',
                showsUserInterface: true,
              ),
            ],
            category: AndroidNotificationCategory.message,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'al_mulk',
      );

      Logger.info(
        'Al-Mulk reminder scheduled at ${reminderTime.hour.toString().padLeft(2, '0')}:${reminderTime.minute.toString().padLeft(2, '0')} (mode: ${canScheduleExact ? 'exact' : 'inexact'})',
      );
    } catch (e) {
      Logger.error('Error scheduling al-mulk reminder', e);
      // Jika exact alarm gagal, coba dengan inexact
      final errorString = e.toString();
      if (errorString.contains('exact_alarms_not_permitted')) {
        try {
          Logger.info('Retrying al-mulk reminder with inexact mode');
          final now = DateTime.now();
          var scheduledDate = tz.TZDateTime(
            tz.local,
            now.year,
            now.month,
            now.day,
            (time ?? const TimeOfDay(hour: 21, minute: 30)).hour,
            (time ?? const TimeOfDay(hour: 21, minute: 30)).minute,
          );
          if (scheduledDate.isBefore(now)) {
            scheduledDate = scheduledDate.add(const Duration(days: 1));
          }
          await _notifications.zonedSchedule(
            300,
            'Al-Mulk',
            'Persiapan tidur, sudah baca al-mulk belum?',
            scheduledDate,
            NotificationDetails(
              android: AndroidNotificationDetails(
                'ibadah_channel',
                'Ibadah',
                channelDescription: 'Reminder untuk ibadah harian',
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
                actions: [
                  const AndroidNotificationAction(
                    'ibadah_sudah',
                    'V',
                    showsUserInterface: true,
                  ),
                  const AndroidNotificationAction(
                    'ibadah_belum',
                    'X',
                    showsUserInterface: true,
                  ),
                ],
                category: AndroidNotificationCategory.message,
              ),
              iOS: const DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
            payload: 'al_mulk',
          );
          Logger.info('Al-Mulk reminder scheduled with inexact mode');
        } catch (retryError) {
          Logger.error('Error retrying with inexact mode', retryError);
        }
      }
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(NotificationResponse response) {
    Logger.info(
      'Notification tapped: id=${response.id}, actionId=${response.actionId}, payload=${response.payload}',
    );
    // Handle action buttons
    if (response.actionId == 'ibadah_sudah') {
      _handleIbadahAction(response.payload ?? '', true);
    } else if (response.actionId == 'ibadah_belum') {
      _handleIbadahAction(response.payload ?? '', false);
    } else if (response.payload != null) {
      // Handle tap on notification (bukan action button)
      final payload = response.payload!;

      // Handle daily report reminder navigation
      if (payload.startsWith('daily_report:')) {
        final kelompokIdStr = payload.split(':')[1];
        final kelompokId = int.tryParse(kelompokIdStr);
        if (kelompokId != null) {
          Logger.info('Navigating to report input for kelompok $kelompokId');
          Get.toNamed(
            AppRoutes.reportInput,
            arguments: {'kelompokId': kelompokId},
          );
        }
      } else if (payload == 'sholat_dhuha' || payload == 'al_mulk') {
        // Buka halaman tracking atau tampilkan dialog
        Logger.info('Opening ibadah tracking for: $payload');
      }
    }
  }

  /// Handle ibadah action (sudah/belum)
  Future<void> _handleIbadahAction(String payload, bool value) async {
    try {
      // Get current user
      final authService = AuthService.instance;
      final user = authService.currentUser;
      if (user == null) {
        Logger.warning('User not logged in, cannot update ibadah');
        return;
      }

      final today = AppDateUtils.formatDate(DateTime.now());

      if (payload == 'sholat_dhuha') {
        await _firestore.saveDailyIbadah(user.uid, today, sholatDhuha: value);
        Logger.info('Sholat dhuha updated: $value');
      } else if (payload == 'al_mulk') {
        await _firestore.saveDailyIbadah(user.uid, today, alMulk: value);
        Logger.info('Al-Mulk updated: $value');
      }
    } catch (e) {
      Logger.error('Error handling ibadah action', e);
    }
  }

  /// Cancel all reminders
  Future<void> cancelAllReminders() async {
    await _notifications.cancel(100); // Daily report
    await _notifications.cancel(200); // Sholat dhuha
    await _notifications.cancel(300); // Al-Mulk
  }

  /// Check if report already submitted today
  Future<bool> hasReportToday(int kelompokId) async {
    try {
      final today = AppDateUtils.formatDate(DateTime.now());
      final report = await _firestore.getDailyReportById('$kelompokId-$today');
      return report != null && report.status != 'draft';
    } catch (e) {
      Logger.error('Error checking report today', e);
      return false;
    }
  }

  /// Test notification (for debugging)
  Future<void> showTestNotification() async {
    try {
      Logger.info('Showing test notification...');
      await createHighImportanceChannel();

      await _notifications.show(
        9999,
        'Test Notification',
        'Ini adalah test notifikasi. Jika Anda melihat ini, local notification berfungsi dengan baik.',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription:
                'This channel is used for important notifications',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: 'test_notification',
      );

      Logger.info('Test notification shown successfully');
    } catch (e) {
      Logger.error('Error showing test notification', e);
    }
  }

  /// Get notification permission status
  Future<Map<String, dynamic>> getPermissionStatus() async {
    final status = <String, dynamic>{
      'initialized': _initialized,
      'timezone': tz.local.name,
    };

    try {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        final notificationPermission = await androidPlugin
            .requestNotificationsPermission();
        final exactAlarmPermission = await androidPlugin
            .canScheduleExactNotifications();

        status['android_notification_permission'] = notificationPermission;
        status['android_exact_alarm_permission'] = exactAlarmPermission;
      }

      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (iosPlugin != null) {
        // iOS permission check
        status['ios_permission'] = 'check_manually';
      }

      // Check pending notifications
      try {
        final pending = await _notifications.pendingNotificationRequests();
        status['pending_notifications_count'] = pending.length;
        status['pending_notifications'] = pending
            .map((n) => {'id': n.id, 'title': n.title, 'body': n.body})
            .toList();
      } catch (e) {
        status['pending_notifications_error'] = e.toString();
      }
    } catch (e) {
      status['error'] = e.toString();
    }

    return status;
  }

  /// Get all scheduled reminders
  Future<List<PendingNotificationRequest>> getScheduledReminders() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      Logger.error('Error getting scheduled reminders', e);
      return [];
    }
  }

  /// Cancel specific reminder by notification ID
  Future<void> cancelReminder(int notificationId) async {
    try {
      await _notifications.cancel(notificationId);
      Logger.info('Reminder cancelled: $notificationId');
    } catch (e) {
      Logger.error('Error cancelling reminder', e);
      rethrow;
    }
  }

  /// Update reminder schedule based on settings
  /// This will be called when user updates reminder settings
  Future<void> updateReminderSchedule({
    required String type,
    required bool enabled,
    required TimeOfDay time,
    required String userId,
    int? kelompokId,
  }) async {
    try {
      // Cancel existing reminder first
      int notificationId;
      switch (type) {
        case 'daily_report':
          notificationId = 100;
          if (!enabled) {
            await cancelReminder(notificationId);
            return;
          }
          if (kelompokId == null) {
            Logger.warning(
              'Cannot schedule daily report reminder without kelompokId',
            );
            return;
          }
          await scheduleDailyReportReminder(kelompokId: kelompokId, time: time);
          break;
        case 'sholat_dhuha':
          notificationId = 200;
          if (!enabled) {
            await cancelReminder(notificationId);
            return;
          }
          await scheduleSholatDhuhaReminder(userId: userId, time: time);
          break;
        case 'al_mulk':
          notificationId = 300;
          if (!enabled) {
            await cancelReminder(notificationId);
            return;
          }
          await scheduleAlMulkReminder(userId: userId, time: time);
          break;
        default:
          Logger.warning('Unknown reminder type: $type');
          return;
      }
      Logger.info('Reminder schedule updated: $type');
    } catch (e) {
      Logger.error('Error updating reminder schedule', e);
      rethrow;
    }
  }
}
