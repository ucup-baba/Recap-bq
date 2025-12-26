import 'package:get/get.dart';

import '../../core/utils/logger.dart';
import '../../data/services/firestore_service.dart';

class ViolationMonitoringController extends GetxController {
  final _firestore = FirestoreService.instance;

  final violators = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadViolators();
  }

  Future<void> loadViolators() async {
    try {
      isLoading.value = true;
      final users = await _firestore.getUsersWithViolations();
      violators.value = users;
      isLoading.value = false;
    } catch (e) {
      Logger.error('Error loading violators', e);
      isLoading.value = false;
    }
  }
}

