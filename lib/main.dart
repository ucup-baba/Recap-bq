import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/core/constants/app_constants.dart';
import 'app/core/routes/app_pages.dart';
import 'app/core/theme/app_theme.dart';
import 'app/data/services/auth_service.dart';
import 'app/data/services/notification_service.dart';
import 'firebase_options.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase (required for background handler)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize local notifications plugin
  final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

  // Android initialization
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();
  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await localNotifications.initialize(initSettings);

  // Create high importance channel for heads-up notifications
  const androidChannel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  final androidPlugin = localNotifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  await androidPlugin?.createNotificationChannel(androidChannel);

  // Show notification
  final notification = message.notification;
  if (notification != null) {
    await localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
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
      payload: message.data.toString(),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register background message handler (MUST be before runApp)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize date formatting for Indonesian locale
  try {
    await initializeDateFormatting('id_ID', null);
  } catch (e) {
    // Ignore error if locale already initialized
  }

  // Initialize notification services
  await NotificationService.instance.initialize();

  runApp(const PiketAsramaProApp());
}

class PiketAsramaProApp extends StatelessWidget {
  const PiketAsramaProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Piket Asrama Pro',
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.splash,
      getPages: AppPages.routes,
      theme: AppTheme.light(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndRedirect();
  }

  Future<void> _checkAuthAndRedirect() async {
    final user = AuthService.instance.currentUser;
    if (user != null) {
      // User is logged in, load profile and redirect
      final profile = await AuthService.instance.loadUserProfile(user.uid);
      if (profile != null && mounted) {
        if (profile.role == AppConstants.userRoleAdmin) {
          Get.offAllNamed(AppRoutes.adminDashboard);
        } else {
          Get.offAllNamed(AppRoutes.santriDashboard);
        }
        return;
      }
    }
    // User not logged in or profile not found - show auth screen
    // This will be handled by StreamBuilder below
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          // Navigate to auth page using GetX routing to ensure binding is called
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.offAllNamed(AppRoutes.auth);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // User logged in - load profile and redirect
        return FutureBuilder(
          future: AuthService.instance.loadUserProfile(user.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final profile = profileSnapshot.data;
            if (profile == null) {
              // Profile not found, navigate to auth
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Get.offAllNamed(AppRoutes.auth);
              });
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // Redirect based on role using GetX navigation
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (profile.role == AppConstants.userRoleAdmin) {
                Get.offAllNamed(AppRoutes.adminDashboard);
              } else {
                Get.offAllNamed(AppRoutes.santriDashboard);
              }
            });

            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
        );
      },
    );
  }
}
