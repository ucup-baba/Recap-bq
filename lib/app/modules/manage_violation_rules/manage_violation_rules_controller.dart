import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/utils/logger.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/violation_rule_model.dart';
import '../../data/services/firestore_service.dart';

class ManageViolationRulesController extends GetxController {
  final _firestore = FirestoreService.instance;

  final rules = <ViolationRuleModel>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadRules();
  }

  Future<void> loadRules() async {
    try {
      isLoading.value = true;
      _firestore.getViolationRules().listen((loadedRules) {
        rules.value = loadedRules;
        isLoading.value = false;
      });
    } catch (e) {
      Logger.error('Error loading violation rules', e);
      isLoading.value = false;
      SnackbarHelper.showError('Gagal memuat aturan');
    }
  }

  Future<void> createRule(ViolationRuleModel rule) async {
    try {
      await _firestore.createViolationRule(rule);
      SnackbarHelper.showSuccess('Aturan berhasil ditambahkan');
    } catch (e) {
      Logger.error('Error creating violation rule', e);
      SnackbarHelper.showError('Gagal menambahkan aturan');
    }
  }

  Future<void> updateRule(String id, ViolationRuleModel rule) async {
    try {
      await _firestore.updateViolationRule(id, rule);
      SnackbarHelper.showSuccess('Aturan berhasil diperbarui');
    } catch (e) {
      Logger.error('Error updating violation rule', e);
      SnackbarHelper.showError('Gagal memperbarui aturan');
    }
  }

  Future<void> deleteRule(String id) async {
    try {
      await _firestore.deleteViolationRule(id);
      SnackbarHelper.showSuccess('Aturan berhasil dihapus');
    } catch (e) {
      Logger.error('Error deleting violation rule', e);
      SnackbarHelper.showError('Gagal menghapus aturan');
    }
  }

  void showAddEditDialog({ViolationRuleModel? rule}) {
    final nameController = TextEditingController(text: rule?.name ?? '');
    final categoryController = TextEditingController(
      text: rule?.category ?? '',
    );
    final requiresTimeDetail = (rule?.requiresTimeDetail ?? false).obs;

    final categories = ['Sholat', 'Kebersihan', 'Kedisiplinan', 'Lainnya'];

    Get.dialog(
      Dialog(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule == null ? 'Tambah Aturan' : 'Edit Aturan',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Pelanggaran',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: categoryController.text.isEmpty
                      ? null
                      : categoryController.text,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(),
                  ),
                  items: categories.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      categoryController.text = value;
                    }
                  },
                ),
                const SizedBox(height: 16),
                Obx(
                  () => SwitchListTile(
                    title: const Text('Butuh Detail Waktu'),
                    subtitle: const Text(
                      'Aktifkan jika pelanggaran memerlukan detail waktu (misal: Sholat)',
                    ),
                    value: requiresTimeDetail.value,
                    onChanged: (value) => requiresTimeDetail.value = value,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.isEmpty ||
                            categoryController.text.isEmpty) {
                          SnackbarHelper.showError(
                            'Nama dan kategori harus diisi',
                          );
                          return;
                        }

                        final now = DateTime.now();
                        final newRule = ViolationRuleModel(
                          id: rule?.id ?? '',
                          name: nameController.text,
                          category: categoryController.text,
                          requiresTimeDetail: requiresTimeDetail.value,
                          createdAt: rule?.createdAt ?? now,
                          updatedAt: now,
                        );

                        if (rule == null) {
                          await createRule(newRule);
                        } else {
                          await updateRule(rule.id, newRule);
                        }

                        Get.back();
                      },
                      child: Text(rule == null ? 'Tambah' : 'Simpan'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showDeleteDialog(ViolationRuleModel rule) {
    Get.dialog(
      AlertDialog(
        title: const Text('Hapus Aturan'),
        content: Text('Yakin ingin menghapus aturan "${rule.name}"?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              await deleteRule(rule.id);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
