import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/reading_tracker_controller.dart';
import '../../core/utils/logger.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/gemini_service.dart';
import '../../data/services/nalya_service.dart';

class NalyaCheckInController extends GetxController {
  final _nalyaService = NalyaService.instance;
  final _authService = AuthService.instance;

  final currentQuestion = 0.obs;
  final isLoading = false.obs;

  // Question responses
  final nickname = ''.obs; // Nama panggilan untuk Nalya
  final selectedMood = Rxn<String>();
  final weeklyTarget = ''.obs;
  final selectedFocusAmalan = <String>[].obs;
  final challenges = ''.obs;
  final reminderTime = '06:00'.obs;
  final selectedBook = ''.obs;
  final readingTarget = 50.obs;
  final continueLastBook = false.obs;

  String? lastBook;
  int? lastBookProgress;

  // Flag to check if nickname already exists
  final hasExistingNickname = false.obs;

  // Dynamic total questions (6 if nickname exists, 7 if first time)
  int get totalQuestions => hasExistingNickname.value ? 6 : 7;

  @override
  void onInit() {
    super.onInit();
    _loadLastWeekData();
  }

  Future<void> _loadLastWeekData() async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) return;

      final profile = await _nalyaService.getNalyaProfile(userId);
      if (profile != null) {
        lastBook = profile.currentBook;
        lastBookProgress = profile.pagesReadThisWeek;

        // Check if nickname already exists
        if (profile.nickname != null && profile.nickname!.trim().isNotEmpty) {
          hasExistingNickname.value = true;
          nickname.value = profile.nickname!;
        }
      }
    } catch (e) {
      Logger.error('Error loading last week data', e);
    }
  }

  void nextQuestion() {
    if (currentQuestion.value < totalQuestions - 1) {
      currentQuestion.value++;
    }
  }

  void previousQuestion() {
    if (currentQuestion.value > 0) {
      currentQuestion.value--;
    }
  }

  void selectMood(String mood) {
    selectedMood.value = mood;
  }

  void toggleFocusAmalan(String amalan) {
    if (selectedFocusAmalan.contains(amalan)) {
      selectedFocusAmalan.remove(amalan);
    } else {
      selectedFocusAmalan.add(amalan);
    }
  }

  Future<void> submitCheckIn() async {
    try {
      isLoading.value = true;

      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        Get.snackbar(
          'Error',
          'User tidak ditemukan',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Prepare responses
      final responses = {
        'nickname': nickname.value.trim().isNotEmpty
            ? nickname.value.trim()
            : null,
        'mood': selectedMood.value,
        'target': weeklyTarget.value,
        'focusAmalan': selectedFocusAmalan.toList(),
        'challenges': challenges.value,
        'reminderTime': reminderTime.value,
        'book': continueLastBook.value && lastBook != null
            ? lastBook!
            : selectedBook.value,
        'readingTarget': readingTarget.value,
        'continueLastBook': continueLastBook.value,
      };

      await _nalyaService.saveCheckInResponses(userId, responses);

      // Refresh reading tracker data
      if (Get.isRegistered<ReadingTrackerController>()) {
        Get.find<ReadingTrackerController>().loadReadingData();
      }

      // Generate AI feedback
      final geminiService = GeminiService.instance;
      final feedback = await geminiService.generateCheckInFeedback(responses);

      // Save feedback to profile
      await _nalyaService.saveDailyFeedback(userId, feedback);

      Get.back(); // Close modal

      // Show feedback dialog
      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: EdgeInsets.zero,
          content: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Pesan dari Nalya 💙',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    feedback,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Bismillah, Semangat! 💪'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      Logger.info('Nalya check-in submitted successfully with AI feedback');
    } catch (e) {
      Logger.error('Error submitting check-in', e);
      Get.snackbar(
        'Error',
        'Gagal menyimpan check-in: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Get the actual question index (adjusted based on whether nickname question is shown)
  int get _adjustedQuestionIndex {
    // If nickname already exists, question flow is the same (0-5)
    // If nickname doesn't exist, question 0 is nickname, then 1-6 are the regular ones
    if (hasExistingNickname.value) {
      return currentQuestion.value;
    } else {
      return currentQuestion.value -
          1; // Shift by 1 because question 0 is nickname
    }
  }

  bool get canProceed {
    // If showing nickname question (first time user, question 0)
    if (!hasExistingNickname.value && currentQuestion.value == 0) {
      return nickname.value.trim().isNotEmpty;
    }

    // Regular questions
    final adjustedIndex = _adjustedQuestionIndex;
    switch (adjustedIndex) {
      case 0:
        return selectedMood.value != null;
      case 1:
        return weeklyTarget.value.trim().isNotEmpty;
      case 2:
        return selectedFocusAmalan.isNotEmpty;
      case 3:
        return challenges.value.trim().isNotEmpty;
      case 4:
        return true; // Reminder time has default
      case 5:
        if (continueLastBook.value) return true;
        return selectedBook.value.trim().isNotEmpty;
      default:
        return false;
    }
  }

  bool get canSubmit {
    final hasNickname =
        hasExistingNickname.value || nickname.value.trim().isNotEmpty;
    return hasNickname &&
        selectedMood.value != null &&
        weeklyTarget.value.trim().isNotEmpty &&
        selectedFocusAmalan.isNotEmpty &&
        challenges.value.trim().isNotEmpty &&
        (continueLastBook.value || selectedBook.value.trim().isNotEmpty);
  }
}
