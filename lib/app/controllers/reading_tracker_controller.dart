import 'package:get/get.dart';

import '../core/utils/logger.dart';
import '../data/services/auth_service.dart';
import '../data/services/nalya_service.dart';

class ReadingTrackerController extends GetxController {
  static ReadingTrackerController get instance =>
      Get.find<ReadingTrackerController>();

  final _nalyaService = NalyaService.instance;
  final _authService = AuthService.instance;

  final currentBook = Rxn<String>();
  final pagesReadThisWeek = 0.obs;
  final readingTarget = 50.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadReadingData();
  }

  Future<void> loadReadingData() async {
    try {
      isLoading.value = true;
      final userId = _authService.currentUser?.uid;
      if (userId == null) return;

      final profile = await _nalyaService.getNalyaProfile(userId);
      if (profile != null) {
        // Treat empty string as null
        final bookName = profile.currentBook;
        currentBook.value = (bookName != null && bookName.trim().isNotEmpty)
            ? bookName
            : null;
        pagesReadThisWeek.value = profile.pagesReadThisWeek;
        readingTarget.value = profile.readingTarget;
        Logger.info(
          'Reading data loaded: book="${currentBook.value}", pages=${pagesReadThisWeek.value}/${readingTarget.value}',
        );
      } else {
        Logger.info('No Nalya profile found');
      }
    } catch (e) {
      Logger.error('Error loading reading data', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logReading(int pages, {String? notes}) async {
    try {
      isLoading.value = true;
      final userId = _authService.currentUser?.uid;
      if (userId == null) return;

      await _nalyaService.logReadingProgress(
        userId: userId,
        bookTitle: currentBook.value ?? 'Belum ada',
        pagesRead: pages,
        currentPage: pagesReadThisWeek.value + pages,
        totalPages: 0,
        notes: notes,
      );

      // Refresh data
      await loadReadingData();
      Logger.info('Reading progress logged: $pages pages');
    } catch (e) {
      Logger.error('Error logging reading', e);
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }
}
