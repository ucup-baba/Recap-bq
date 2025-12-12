import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';

import '../../core/routes/app_pages.dart';
import '../../core/utils/logger.dart';
import 'auth_service.dart';
import 'firestore_service.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  Logger.info('Background message received: ${message.messageId}');
}

class FCMService {
  FCMService._();
  static final FCMService instance = FCMService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final _firestore = FirestoreService.instance;
  final _authService = AuthService.instance;

  String? _fcmToken;
  bool _initialized = false;

  String? get fcmToken => _fcmToken;

  /// Initialize FCM service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        Logger.info('User granted notification permission');

        // Get FCM token
        _fcmToken = await _messaging.getToken();
        if (_fcmToken != null) {
          Logger.info('FCM Token: $_fcmToken');
          await _saveTokenToFirestore(_fcmToken!);
        }

        // Listen for token refresh
        _messaging.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          Logger.info('FCM Token refreshed: $newToken');
          _saveTokenToFirestore(newToken);
        });

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle notification tap when app is in background
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

        // Check if app was opened from notification
        final initialMessage = await _messaging.getInitialMessage();
        if (initialMessage != null) {
          _handleNotificationTap(initialMessage);
        }

        // Set background message handler
        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

        _initialized = true;
      } else {
        Logger.warning('User declined notification permission');
      }
    } catch (e) {
      Logger.error('Error initializing FCM', e);
    }
  }

  /// Save FCM token to Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        await _firestore.saveFCMToken(user.uid, token);
        Logger.info('FCM token saved to Firestore');
      }
    } catch (e) {
      Logger.error('Error saving FCM token', e);
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    Logger.info('Foreground message received: ${message.messageId}');
    // Show local notification or snackbar
    if (message.notification != null) {
      // You can show a snackbar or local notification here
      Logger.info(
        'Notification: ${message.notification?.title} - ${message.notification?.body}',
      );
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    Logger.info('Notification tapped: ${message.messageId}');
    // Navigate based on notification data
    final data = message.data;
    if (data['type'] == 'report_verified' || data['type'] == 'report_rejected') {
      Get.toNamed(AppRoutes.santriDashboard);
    } else if (data['type'] == 'new_report') {
      Get.toNamed(AppRoutes.adminDashboard);
    }
  }

  /// Get FCM token
  Future<String?> getToken() async {
    if (_fcmToken != null) return _fcmToken;
    _fcmToken = await _messaging.getToken();
    return _fcmToken;
  }
}
