import 'package:get/get.dart';

import '../../core/utils/logger.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/violation_case_model.dart';
import '../../data/models/violation_rule_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firestore_service.dart';

class RecordViolationController extends GetxController {
  final _firestore = FirestoreService.instance;
  final _authService = AuthService.instance;

  final availableRules = <ViolationRuleModel>[].obs;
  final availableMembers = <Map<String, dynamic>>[].obs;
  final selectedRule = Rxn<ViolationRuleModel>();
  final selectedTimeDetail = Rxn<String>();
  final selectedMembers = <String>[].obs; // userIds
  final isLoading = false.obs;
  final isSaving = false.obs;
  final searchQuery = ''.obs;

  final timeDetailOptions = ['Subuh', 'Dzuhur', 'Ashar', 'Maghrib', 'Isya'];

  @override
  void onInit() {
    super.onInit();
    loadRules();
    loadMembers();
  }

  Future<void> loadRules() async {
    try {
      isLoading.value = true;
      _firestore.getViolationRules().listen((rules) {
        availableRules.value = rules;
        isLoading.value = false;
      });
    } catch (e) {
      Logger.error('Error loading violation rules', e);
      isLoading.value = false;
      SnackbarHelper.showError('Gagal memuat aturan');
    }
  }

  Future<void> loadMembers() async {
    try {
      isLoading.value = true;
      final members = await _firestore.getAllGroupMembers();
      availableMembers.value = members;
      isLoading.value = false;
    } catch (e) {
      Logger.error('Error loading members', e);
      isLoading.value = false;
      SnackbarHelper.showError('Gagal memuat anggota');
    }
  }

  void selectRule(ViolationRuleModel? rule) {
    selectedRule.value = rule;
    // Reset time detail when rule changes
    if (rule?.requiresTimeDetail != true) {
      selectedTimeDetail.value = null;
    }
  }

  void selectTimeDetail(String? timeDetail) {
    selectedTimeDetail.value = timeDetail;
  }

  void toggleMember(String userId) {
    if (selectedMembers.contains(userId)) {
      selectedMembers.remove(userId);
    } else {
      selectedMembers.add(userId);
    }
  }

  /// Group members by kelompokId and filter by search query
  /// Cached to avoid recalculating on every access
  Map<int, List<Map<String, dynamic>>> get groupedMembers {
    final Map<int, List<Map<String, dynamic>>> groups = {};
    final query = searchQuery.value.toLowerCase().trim();

    for (final member in availableMembers) {
      final kelompokId = member['kelompokId'] as int;
      final displayName = (member['displayName'] as String? ?? '').toLowerCase();

      // Filter by search query
      if (query.isEmpty || displayName.contains(query)) {
        groups.putIfAbsent(kelompokId, () => []).add(member);
      }
    }

    // Sort members within each group by displayName
    for (final group in groups.values) {
      group.sort((a, b) {
        final nameA = (a['displayName'] as String? ?? '').toLowerCase();
        final nameB = (b['displayName'] as String? ?? '').toLowerCase();
        return nameA.compareTo(nameB);
      });
    }

    return groups;
  }

  /// Check if all visible members in a group are selected
  bool isGroupFullySelected(int kelompokId) {
    final groupMembers = groupedMembers[kelompokId];
    if (groupMembers == null || groupMembers.isEmpty) return false;

    return groupMembers.every((member) {
      final userId = member['userId'] as String?;
      return userId != null && selectedMembers.contains(userId);
    });
  }

  /// Check if some (but not all) visible members in a group are selected
  bool isGroupPartiallySelected(int kelompokId) {
    final groupMembers = groupedMembers[kelompokId];
    if (groupMembers == null || groupMembers.isEmpty) return false;

    final selectedCount = groupMembers.where((member) {
      final userId = member['userId'] as String?;
      return userId != null && selectedMembers.contains(userId);
    }).length;

    return selectedCount > 0 && selectedCount < groupMembers.length;
  }

  /// Toggle selection for all members in a group
  void toggleGroupSelection(int kelompokId) {
    final groupMembers = groupedMembers[kelompokId];
    if (groupMembers == null || groupMembers.isEmpty) return;

    final allSelected = isGroupFullySelected(kelompokId);

    for (final member in groupMembers) {
      final userId = member['userId'] as String?;
      if (userId == null) continue;
      
      if (allSelected) {
        selectedMembers.remove(userId);
      } else {
        if (!selectedMembers.contains(userId)) {
          selectedMembers.add(userId);
        }
      }
    }
  }

  /// Get count of selected members in a group
  int getGroupSelectedCount(int kelompokId) {
    final groupMembers = groupedMembers[kelompokId];
    if (groupMembers == null) return 0;
    
    return groupMembers.where((member) {
      final userId = member['userId'] as String?;
      return userId != null && selectedMembers.contains(userId);
    }).length;
  }

  Future<void> saveViolation() async {
    if (selectedRule.value == null) {
      SnackbarHelper.showError('Pilih jenis pelanggaran terlebih dahulu');
      return;
    }

    if (selectedMembers.isEmpty) {
      SnackbarHelper.showError('Pilih minimal satu anggota');
      return;
    }

    if (selectedRule.value!.requiresTimeDetail &&
        selectedTimeDetail.value == null) {
      SnackbarHelper.showError('Pilih detail waktu terlebih dahulu');
      return;
    }

    try {
      isSaving.value = true;
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        SnackbarHelper.showError('User tidak terautentikasi');
        return;
      }

      final cases = <ViolationCaseModel>[];
      final now = DateTime.now();

      for (final userId in selectedMembers) {
        final member = availableMembers.firstWhere(
          (m) => m['userId'] == userId,
          orElse: () => {
            'userId': userId,
            'displayName': 'Unknown',
            'kelompokId': 0,
          },
        );

        final case_ = ViolationCaseModel(
          id: '', // Will be generated by Firestore
          userId: userId,
          userDisplayName: member['displayName'] as String,
          kelompokId: member['kelompokId'] as int,
          ruleId: selectedRule.value!.id,
          ruleName: selectedRule.value!.name,
          category: selectedRule.value!.category,
          timeDetail: selectedRule.value!.requiresTimeDetail
              ? selectedTimeDetail.value
              : null,
          recordedAt: now,
          recordedBy: currentUser.uid,
        );

        cases.add(case_);
      }

      await _firestore.recordMultipleViolationCases(cases);
      SnackbarHelper.showSuccess(
        'Berhasil mencatat ${cases.length} kasus pelanggaran',
      );

      // Reset form
      selectedRule.value = null;
      selectedTimeDetail.value = null;
      selectedMembers.clear();

      Get.back();
    } catch (e) {
      Logger.error('Error saving violation', e);
      SnackbarHelper.showError('Gagal menyimpan kasus');
    } finally {
      isSaving.value = false;
    }
  }
}
