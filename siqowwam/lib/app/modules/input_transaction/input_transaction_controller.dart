import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/transaction_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/models/user_model.dart';

/// Input Transaction Controller
class InputTransactionController extends GetxController {
  final TransactionService _transactionService = TransactionService();
  final AuthService _authService = AuthService();

  // Form controllers
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();
  final subjectController = TextEditingController();

  // Observables
  final selectedDate = DateTime.now().obs;
  final selectedCategory = 'Cash'.obs;
  final isLoading = false.obs;
  final currentUser = Rxn<UserModel>();

  // Income Categories - Cash, Transfer, Pondok
  final categories = ['Cash', 'Transfer', 'Pondok'];

  @override
  void onInit() {
    super.onInit();
    _loadUser();
  }

  @override
  void onClose() {
    amountController.dispose();
    descriptionController.dispose();
    subjectController.dispose();
    super.onClose();
  }

  Future<void> _loadUser() async {
    currentUser.value = await _authService.getCurrentUserModel();
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

      await _transactionService.createIncomeTransaction(
        user: currentUser.value!,
        amount: amount,
        category: selectedCategory.value,
        description: descriptionController.text.trim(),
        subject: subjectController.text.trim().isNotEmpty
            ? subjectController.text.trim()
            : null,
        date: selectedDate.value,
      );

      Get.snackbar(
        'Sukses',
        'Transaksi berhasil disimpan',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade400,
        colorText: Colors.white,
      );

      // Reset form
      amountController.clear();
      descriptionController.clear();
      subjectController.clear();
      selectedDate.value = DateTime.now();
      selectedCategory.value = 'Cash';

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menyimpan: $e',
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
