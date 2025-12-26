import 'package:get/get.dart';

import '../../core/utils/logger.dart';
import '../../data/models/violation_case_model.dart';
import '../../data/services/firestore_service.dart';

class ViolationDetailController extends GetxController {
  final _firestore = FirestoreService.instance;

  final cases = <ViolationCaseModel>[].obs;
  final userInfo = Rxn<Map<String, dynamic>>();
  final isLoading = false.obs;
  final errorMessage = Rxn<String>();

  String? userId;

  @override
  void onInit() {
    super.onInit();
    userId = Get.arguments as String?;
    if (userId != null) {
      loadCases(userId!);
    }
  }

  Future<void> loadCases(String userId) async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      
      _firestore.getViolationCasesByUser(userId).listen(
        (loadedCases) {
          cases.value = loadedCases;
          if (loadedCases.isNotEmpty) {
            final firstCase = loadedCases.first;
            userInfo.value = {
              'userId': userId,
              'displayName': firstCase.userDisplayName,
              'kelompokId': firstCase.kelompokId,
            };
          }
          isLoading.value = false;
        },
        onError: (error) {
          Logger.error('Error in violation cases stream', error);
          isLoading.value = false;
          
          // Check if it's an index error
          final errorString = error.toString();
          if (errorString.contains('FAILED_PRECONDITION') ||
              errorString.contains('requires an index')) {
            errorMessage.value =
                'Index Firestore sedang dibuat. Silakan tunggu beberapa menit dan coba lagi.';
          } else {
            errorMessage.value = 'Gagal memuat data pelanggaran. Silakan coba lagi.';
          }
        },
      );
    } catch (e) {
      Logger.error('Error loading violation cases', e);
      isLoading.value = false;
      
      final errorString = e.toString();
      if (errorString.contains('FAILED_PRECONDITION') ||
          errorString.contains('requires an index')) {
        errorMessage.value =
            'Index Firestore sedang dibuat. Silakan tunggu beberapa menit dan coba lagi.';
      } else {
        errorMessage.value = 'Gagal memuat data pelanggaran. Silakan coba lagi.';
      }
    }
  }
}

