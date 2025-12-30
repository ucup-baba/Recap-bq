import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/date_utils.dart';
import '../../core/utils/logger.dart';
import '../models/nalya_profile_model.dart';
import '../models/reading_log_model.dart';

class NalyaService {
  static final NalyaService _instance = NalyaService._internal();
  factory NalyaService() => _instance;
  NalyaService._internal();

  static NalyaService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get Nalya profile
  Future<NalyaProfileModel?> getNalyaProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('nalya_profile')
          .doc('profile')
          .get();

      if (!doc.exists) return null;
      return NalyaProfileModel.fromMap(doc.data()!);
    } catch (e) {
      Logger.error('Error getting Nalya profile', e);
      return null;
    }
  }

  // Save weekly check-in responses
  Future<void> saveCheckInResponses(
    String userId,
    Map<String, dynamic> responses,
  ) async {
    try {
      final today = AppDateUtils.formatDate(DateTime.now());

      // Build profile data
      final profileData = <String, dynamic>{
        'lastCheckInDate': today,
        'currentMood': responses['mood'],
        'weeklyTarget': responses['target'],
        'focusAmalan': responses['focusAmalan'],
        'challenges': responses['challenges'],
        'reminderTime': responses['reminderTime'],
        'currentBook': responses['book'],
        'bookStartDate': today,
        'readingTarget': responses['readingTarget'] ?? 50,
        'pagesReadThisWeek': 0, // Reset weekly counter
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Only set nickname if provided (first time only)
      if (responses['nickname'] != null) {
        profileData['nickname'] = responses['nickname'];
      }

      // Save to profile
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('nalya_profile')
          .doc('profile')
          .set(profileData, SetOptions(merge: true));

      // Save to history
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('nalya_history')
          .doc(today)
          .set({
            'checkInResponses': responses,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      Logger.info('Nalya check-in saved for $userId');
    } catch (e) {
      Logger.error('Error saving check-in responses', e);
      rethrow;
    }
  }

  // Save daily feedback
  Future<void> saveDailyFeedback(String userId, String feedback) async {
    try {
      final today = AppDateUtils.formatDate(DateTime.now());

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('nalya_profile')
          .doc('profile')
          .set({
            'lastFeedback': feedback,
            'lastFeedbackDate': today,
          }, SetOptions(merge: true));

      // Also save to history
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('nalya_history')
          .doc(today)
          .set({
            'dailyFeedback': feedback,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      Logger.info('Nalya feedback saved for $userId');
    } catch (e) {
      Logger.error('Error saving daily feedback', e);
      rethrow;
    }
  }

  // Check if should show check-in (Monday & not done yet)
  Future<bool> shouldShowCheckIn(String userId) async {
    try {
      final now = DateTime.now();
      if (now.weekday != DateTime.monday) return false;

      final today = AppDateUtils.formatDate(now);
      final profile = await getNalyaProfile(userId);

      return profile?.lastCheckInDate != today;
    } catch (e) {
      Logger.error('Error checking if should show check-in', e);
      return false;
    }
  }

  // Check if should generate new feedback
  Future<bool> shouldGenerateNewFeedback(String userId) async {
    try {
      final today = AppDateUtils.formatDate(DateTime.now());
      final profile = await getNalyaProfile(userId);

      return profile?.lastFeedbackDate != today;
    } catch (e) {
      Logger.error('Error checking if should generate feedback', e);
      return true; // Generate jika error
    }
  }

  // Log reading progress
  Future<void> logReadingProgress({
    required String userId,
    required String bookTitle,
    required int pagesRead,
    required int currentPage,
    required int totalPages,
    String? notes,
  }) async {
    try {
      final today = AppDateUtils.formatDate(DateTime.now());

      final log = ReadingLogModel(
        bookTitle: bookTitle,
        pagesRead: pagesRead,
        currentPage: currentPage,
        totalPages: totalPages,
        notes: notes,
        timestamp: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('reading_log')
          .doc(today)
          .set(log.toMap());

      // Update weekly counter
      final profile = await getNalyaProfile(userId);
      final newTotal = (profile?.pagesReadThisWeek ?? 0) + pagesRead;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('nalya_profile')
          .doc('profile')
          .set({
            'pagesReadThisWeek': newTotal,
            'currentBook': bookTitle,
          }, SetOptions(merge: true));

      Logger.info('Reading progress logged: $pagesRead pages');
    } catch (e) {
      Logger.error('Error logging reading progress', e);
      rethrow;
    }
  }

  // Get weekly reading progress
  Future<int> getWeeklyReadingProgress(String userId) async {
    try {
      final profile = await getNalyaProfile(userId);
      return profile?.pagesReadThisWeek ?? 0;
    } catch (e) {
      Logger.error('Error getting weekly reading progress', e);
      return 0;
    }
  }

  // Complete book
  Future<void> completeBook(String userId, String bookTitle) async {
    try {
      final today = AppDateUtils.formatDate(DateTime.now());

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('nalya_profile')
          .doc('profile')
          .set({
            'lastBookCompleted': bookTitle,
            'lastBookCompletedDate': today,
            'currentBook': null,
            'bookStartDate': null,
          }, SetOptions(merge: true));

      Logger.info('Book completed: $bookTitle');
    } catch (e) {
      Logger.error('Error completing book', e);
      rethrow;
    }
  }

  // Reset weekly reading counter (called every Monday)
  Future<void> resetWeeklyReadingCounter(String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('nalya_profile')
          .doc('profile')
          .set({'pagesReadThisWeek': 0}, SetOptions(merge: true));

      Logger.info('Weekly reading counter reset for $userId');
    } catch (e) {
      Logger.error('Error resetting weekly counter', e);
    }
  }
}
