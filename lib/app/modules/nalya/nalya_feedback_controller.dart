import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/utils/logger.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firestore_service.dart';
import '../../data/services/gemini_service.dart';
import '../../data/services/ibadah_tracking_service.dart';
import '../../data/services/nalya_service.dart';

class NalyaFeedbackController extends GetxController {
  final _nalyaService = NalyaService.instance;
  final _geminiService = GeminiService.instance;
  final _ibadahService = IbadahTrackingService.instance;
  final _firestoreService = FirestoreService.instance;

  final isLoading = false.obs;
  final feedback = ''.obs;
  final showFeedback = true.obs;

  // Weekly check-in lock
  final hasCheckedInThisWeek = false.obs;
  final nextMondayDate = ''.obs;

  String? _currentUserId;

  @override
  void onInit() {
    super.onInit();
    _calculateNextMonday();
    _loadTodayFeedback();
  }

  /// Calculate next Monday 06:00
  void _calculateNextMonday() {
    final now = DateTime.now();
    // Calculate days until next Monday (weekday 1)
    int daysUntilMonday = (DateTime.monday - now.weekday + 7) % 7;
    if (daysUntilMonday == 0) {
      // If today is Monday, check if it's before 06:00
      if (now.hour >= 6) {
        daysUntilMonday = 7; // Next week's Monday
      }
    }
    final nextMonday = DateTime(
      now.year,
      now.month,
      now.day + daysUntilMonday,
      6,
      0,
    );
    nextMondayDate.value = DateFormat(
      'd MMMM yyyy',
      'id_ID',
    ).format(nextMonday);
  }

  /// Check if a date is in the current week (Monday-Sunday)
  bool _isDateInCurrentWeek(String? dateString) {
    if (dateString == null || dateString.isEmpty) return false;

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();

      // Get start of current week (Monday 00:00)
      final daysFromMonday = (now.weekday - DateTime.monday);
      final startOfWeek = DateTime(
        now.year,
        now.month,
        now.day - daysFromMonday,
      );

      // Get end of current week (Sunday 23:59)
      final endOfWeek = startOfWeek.add(
        const Duration(days: 6, hours: 23, minutes: 59),
      );

      return date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
          date.isBefore(endOfWeek.add(const Duration(seconds: 1)));
    } catch (e) {
      return false;
    }
  }

  Future<void> _loadTodayFeedback() async {
    try {
      isLoading.value = true;
      Logger.info('NalyaFeedbackController: Starting to load feedback...');

      // Wait a bit for auth to be ready
      await Future.delayed(const Duration(milliseconds: 500));

      // Get user ID from AuthService if not set
      if (_currentUserId == null) {
        final user = AuthService.instance.currentUser;
        if (user?.uid != null) {
          _currentUserId = user?.uid;
          Logger.info(
            'NalyaFeedbackController: Got userId from AuthService: $_currentUserId',
          );
        }
      }

      // If still null, try harder to get user ID
      if (_currentUserId == null) {
        Logger.warning(
          'NalyaFeedbackController: userId is still null, showing fallback',
        );
        feedback.value =
            'Assalamu\'alaikum! Semangat menjalani hari ini ya! 💪';
        isLoading.value = false;
        return;
      }

      // Load profile to check weekly check-in status
      final profile = await _nalyaService.getNalyaProfile(_currentUserId!);

      // Check if already checked in this week
      if (profile != null && profile.lastCheckInDate != null) {
        hasCheckedInThisWeek.value = _isDateInCurrentWeek(
          profile.lastCheckInDate,
        );
        Logger.info(
          'NalyaFeedbackController: lastCheckInDate=${profile.lastCheckInDate}, hasCheckedInThisWeek=${hasCheckedInThisWeek.value}',
        );
      } else {
        hasCheckedInThisWeek.value = false;
      }

      // Always generate fresh feedback on each login
      Logger.info(
        'NalyaFeedbackController: Generating fresh feedback on login...',
      );
      await generateFeedback();
    } catch (e) {
      Logger.error('Error loading today feedback', e);
      feedback.value = 'Tetap semangat hari ini! 💪';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> generateFeedback() async {
    try {
      isLoading.value = true;

      final userId = _currentUserId;
      if (userId == null) {
        Logger.error('Cannot generate feedback: userId is null', null);
        return;
      }

      // Get user data
      final user = await _firestoreService.fetchUser(userId);
      if (user == null) return;

      // Get Nalya profile
      final profile = await _nalyaService.getNalyaProfile(userId);

      // Analyze ibadah data (last 7 days)
      final ibadahData = await _analyzeIbadahData(userId);

      // Analyze reading data
      final readingData = await _analyzeReadingData(userId);

      // Build context for AI
      // Use nickname if available, otherwise fallback to displayName
      final callingName =
          (profile?.nickname != null && profile!.nickname!.trim().isNotEmpty)
          ? profile.nickname!
          : user.displayName;

      final context = {
        'displayName': callingName,
        'role': user.role,
        'currentMood': profile?.currentMood ?? 'biasa',
        'weeklyTarget': profile?.weeklyTarget ?? '',
        'focusAmalan': profile?.focusAmalan ?? [],
        'challenges': profile?.challenges ?? '',
        'ibadahData': ibadahData,
        'readingData': readingData,
      };

      // Generate feedback using Gemini
      final generatedFeedback = await _geminiService.generateDailyFeedback(
        context,
      );
      feedback.value = generatedFeedback;

      // Save to cache
      await _nalyaService.saveDailyFeedback(userId, generatedFeedback);

      Logger.info('Feedback generated successfully');
    } catch (e) {
      Logger.error('Error generating feedback', e);
      // Fallback message
      feedback.value = 'Tetap semangat hari ini! 💪';
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> _analyzeIbadahData(String userId) async {
    try {
      final weekData = await _ibadahService.getWeeklyIbadahData(userId: userId);

      // Calculate percentages for each sholat
      int subuhCount = 0,
          dzuhurCount = 0,
          asharCount = 0,
          maghribCount = 0,
          isyaCount = 0,
          dhuhaCount = 0,
          tahajudCount = 0;
      int totalPushup = 0;
      int daysWithData = 0;

      for (final day in weekData) {
        if (day.date.isNotEmpty) {
          daysWithData++;
          if (day.subuhJamaah == true) subuhCount++;
          if (day.dzuhurJamaah == true) dzuhurCount++;
          if (day.asharJamaah == true) asharCount++;
          if (day.maghribJamaah == true) maghribCount++;
          if (day.isyaJamaah == true) isyaCount++;
          if (day.sholatDhuha == true) dhuhaCount++;
          if (day.tahajud == true) tahajudCount++;
          totalPushup += day.pushup ?? 0;
        }
      }

      final daysToCount = daysWithData > 0 ? daysWithData : 1;

      return {
        'subuhPercent': ((subuhCount / daysToCount) * 100).toStringAsFixed(1),
        'dzuhurPercent': ((dzuhurCount / daysToCount) * 100).toStringAsFixed(1),
        'asharPercent': ((asharCount / daysToCount) * 100).toStringAsFixed(1),
        'maghribPercent': ((maghribCount / daysToCount) * 100).toStringAsFixed(
          1,
        ),
        'isyaPercent': ((isyaCount / daysToCount) * 100).toStringAsFixed(1),
        'dhuhaPercent': ((dhuhaCount / daysToCount) * 100).toStringAsFixed(1),
        'tahajudPercent': ((tahajudCount / daysToCount) * 100).toStringAsFixed(
          1,
        ),
        'pushupAvg': (totalPushup / daysToCount).toStringAsFixed(0),
        'pushupTarget': 25,
      };
    } catch (e) {
      Logger.error('Error analyzing ibadah data', e);
      return {};
    }
  }

  Future<Map<String, dynamic>> _analyzeReadingData(String userId) async {
    try {
      final profile = await _nalyaService.getNalyaProfile(userId);
      if (profile == null) {
        return {
          'currentBook': 'Belum ada',
          'pagesReadThisWeek': 0,
          'readingTarget': 50,
        };
      }

      return {
        'currentBook': profile.currentBook ?? 'Belum ada',
        'pagesReadThisWeek': profile.pagesReadThisWeek,
        'readingTarget': profile.readingTarget,
      };
    } catch (e) {
      Logger.error('Error analyzing reading data', e);
      return {
        'currentBook': 'Belum ada',
        'pagesReadThisWeek': 0,
        'readingTarget': 50,
      };
    }
  }

  void dismissFeedback() {
    showFeedback.value = false;
  }

  void showFeedbackAgain() {
    showFeedback.value = true;
  }

  void setUserId(String userId) {
    _currentUserId = userId;
    _loadTodayFeedback();
  }
}
