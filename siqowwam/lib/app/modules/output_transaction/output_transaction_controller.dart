import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/transaction_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/category_service.dart';
import '../../data/models/user_model.dart';

/// Output Transaction Controller
class OutputTransactionController extends GetxController {
  final TransactionService _transactionService = TransactionService();
  final AuthService _authService = AuthService();
  final CategoryService _categoryService = CategoryService();

  // Form controllers
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();
  final subjectController = TextEditingController();

  // SDM subcategories (admin only)
  static const sdmSubcategories = [
    'Honor Guru',
    'Honor Ustad',
    'Honor Pengasuh',
    'Honor Pengabdian',
  ];

  // Categories with subcategories (loaded from Firestore + SDM)
  final allCategories = <String, List<String>>{}.obs;

  // Stream subscriptions
  final Map<String, StreamSubscription> _categorySubscriptions = {};

  // Observables
  final selectedCategory = 'SDM'.obs;
  final selectedSubcategory = 'Honor Guru'.obs;
  final selectedDate = DateTime.now().obs;
  final isLoading = false.obs;
  final currentUser = Rxn<UserModel>();

  @override
  void onInit() {
    super.onInit();
    _loadUser();
    _loadCategories();
  }

  @override
  void onClose() {
    amountController.dispose();
    descriptionController.dispose();
    subjectController.dispose();
    // Cancel all stream subscriptions
    for (final sub in _categorySubscriptions.values) {
      sub.cancel();
    }
    super.onClose();
  }

  Future<void> _loadUser() async {
    currentUser.value = await _authService.getCurrentUserModel();
  }

  void _loadCategories() {
    // Initialize with SDM first
    allCategories.value = {'SDM': sdmSubcategories};

    // Subscribe to each category's subcategories stream
    final categories = [
      'Fasilitas',
      'Pendidikan',
      'Rumah Tangga',
      'Transportasi',
      'Lainnya',
    ];

    for (final cat in categories) {
      _categorySubscriptions[cat] = _categoryService
          .getSubcategoriesStream(cat)
          .listen((subcategories) {
            final updated = Map<String, List<String>>.from(allCategories);
            updated[cat] = subcategories;

            // Reorder to keep SDM first
            final ordered = <String, List<String>>{'SDM': sdmSubcategories};
            for (final c in categories) {
              if (updated.containsKey(c)) {
                ordered[c] = updated[c]!;
              }
            }
            allCategories.value = ordered;
          });
    }
  }

  void setDate(DateTime date) {
    selectedDate.value = date;
  }

  void setCategory(String? category) {
    if (category != null) {
      selectedCategory.value = category;
    }
  }

  Future<void> pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      selectedDate.value = picked;
    }
  }

  bool validate() {
    final amountText = amountController.text.trim();
    if (amountText.isEmpty) {
      Get.snackbar(
        'Error',
        'Masukkan nominal',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
      );
      return false;
    }

    final amount = double.tryParse(
      amountText.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    if (amount == null || amount <= 0) {
      Get.snackbar(
        'Error',
        'Nominal tidak valid',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
      );
      return false;
    }

    if (descriptionController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Masukkan keterangan',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
      );
      return false;
    }

    return true;
  }

  Future<bool> saveTransaction() async {
    if (!validate()) return false;
    if (currentUser.value == null) {
      Get.snackbar(
        'Error',
        'User tidak ditemukan',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
      );
      return false;
    }

    isLoading.value = true;
    try {
      final amount = double.parse(
        amountController.text.trim().replaceAll(RegExp(r'[^0-9]'), ''),
      );

      await _transactionService.createExpenseTransaction(
        user: currentUser.value!,
        amount: amount,
        category: selectedCategory.value,
        subcategory: selectedSubcategory.value,
        description: descriptionController.text.trim(),
        subject: subjectController.text.trim().isNotEmpty
            ? subjectController.text.trim()
            : null,
        date: selectedDate.value,
      );

      Get.snackbar(
        'Sukses',
        'Pengeluaran berhasil disimpan',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade400,
        colorText: Colors.white,
      );

      // Reset form
      amountController.clear();
      descriptionController.clear();
      subjectController.clear();
      selectedDate.value = DateTime.now();
      selectedCategory.value = 'operasional';

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        '$e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
