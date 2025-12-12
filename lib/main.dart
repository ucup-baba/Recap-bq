import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/core/constants/app_constants.dart';
import 'app/core/routes/app_pages.dart';
import 'app/core/theme/app_theme.dart';
import 'app/data/services/auth_service.dart';
import 'app/data/services/notification_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
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
