import 'package:get/get.dart';

import '../../core/utils/logger.dart';
import '../../data/services/firestore_service.dart';

class ViolationMonitoringController extends GetxController {
  final _firestore = FirestoreService.instance;

  final violators = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final selectedKelompok = Rxn<int>(); // null = Semua

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

  void setKelompokFilter(int? kelompokId) {
    selectedKelompok.value = kelompokId;
  }

  List<Map<String, dynamic>> get filteredViolators {
    if (selectedKelompok.value == null) {
      return violators;
    }
    return violators
        .where((v) => v['kelompokId'] == selectedKelompok.value)
        .toList();
  }
}
