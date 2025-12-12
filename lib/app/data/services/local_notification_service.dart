import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

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
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

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
        Logger.info('Local notifications initialized');
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

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(reminderChannel);

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(ibadahChannel);
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    try {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }

      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }

      return false;
    } catch (e) {
      Logger.error('Error requesting notification permissions', e);
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

      // Schedule new reminder
      await _notifications.zonedSchedule(
        100,
        'Jangan Lupa Mengisi Laporan',
        'Jangan lupa mengisi laporan harian hari ini',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminder_channel',
            'Reminder',
            channelDescription: 'Reminder untuk mengisi laporan harian',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      Logger.info(
        'Daily report reminder scheduled at ${reminderTime.hour.toString().padLeft(2, '0')}:${reminderTime.minute.toString().padLeft(2, '0')}',
      );
    } catch (e) {
      Logger.error('Error scheduling daily report reminder', e);
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
                'Sudah',
                showsUserInterface: true,
              ),
              const AndroidNotificationAction(
                'ibadah_belum',
                'Belum',
                showsUserInterface: true,
              ),
            ],
            category: AndroidNotificationCategory.message,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'sholat_dhuha',
      );

      Logger.info(
        'Sholat dhuha reminder scheduled at ${reminderTime.hour.toString().padLeft(2, '0')}:${reminderTime.minute.toString().padLeft(2, '0')}',
      );
    } catch (e) {
      Logger.error('Error scheduling sholat dhuha reminder', e);
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
                'Sudah',
                showsUserInterface: true,
              ),
              const AndroidNotificationAction(
                'ibadah_belum',
                'Belum',
                showsUserInterface: true,
              ),
            ],
            category: AndroidNotificationCategory.message,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'al_mulk',
      );

      Logger.info(
        'Al-Mulk reminder scheduled at ${reminderTime.hour.toString().padLeft(2, '0')}:${reminderTime.minute.toString().padLeft(2, '0')}',
      );
    } catch (e) {
      Logger.error('Error scheduling al-mulk reminder', e);
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
      if (response.payload == 'sholat_dhuha' || response.payload == 'al_mulk') {
        // Buka halaman tracking atau tampilkan dialog
        Logger.info('Opening ibadah tracking for: ${response.payload}');
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
}
