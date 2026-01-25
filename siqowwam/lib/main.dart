import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/core/constants/app_constants.dart';
import 'app/core/routes/app_pages.dart';
import 'app/core/theme/app_theme.dart';
import 'app/data/services/google_sheets_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize date formatting for Indonesian locale
  await initializeDateFormatting('id_ID', null);

  // Load Google Sheets URL from SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final sheetsUrl = prefs.getString('google_sheets_url');
  if (sheetsUrl != null && sheetsUrl.isNotEmpty) {
    GoogleSheetsService.instance.initialize(sheetsUrl);
  }

  runApp(const SIQowwamApp());
}

class SIQowwamApp extends StatelessWidget {
  const SIQowwamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Routes
      initialRoute: AppRoutes.auth,
      getPages: AppPages.pages,

      // Default transition
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
    );
  }
}
