import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import 'input_transaction_controller.dart';

/// Input Transaction View - For adding income transactions
class InputTransactionView extends GetView<InputTransactionController> {
  const InputTransactionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        appBar: AppBar(
          title: const Text('Input Pemasukan'),
          backgroundColor: _getCategoryColor(controller.selectedCategory.value),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount Card
              _buildAmountCard(context),
              const SizedBox(height: 20),

              // Transaction Form
              _buildTransactionForm(context),
            ],
          ),
        ),
        floatingActionButton: Obx(
          () => FloatingActionButton.extended(
            onPressed: controller.isLoading.value
                ? null
                : () async {
                    await controller.saveTransaction();
                  },
            backgroundColor: controller.isLoading.value
                ? Colors.grey
                : _getCategoryColor(controller.selectedCategory.value),
            icon: controller.isLoading.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(controller.isLoading.value ? 'Menyimpan...' : 'Simpan'),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountCard(BuildContext context) {
    final categoryColor = _getCategoryColor(controller.selectedCategory.value);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [categoryColor, categoryColor.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: categoryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.arrow_downward, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'PEMASUKAN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Rp',
            style: TextStyle(color: Colors.white70, fontSize: 20),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller.amountController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
            decoration: const InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(color: Colors.white30, fontSize: 40),
              border: InputBorder.none,
              filled: true,
              fillColor: Colors.black12,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _ThousandsSeparatorInputFormatter(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Detail Transaksi', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),

        // Date picker
        Obx(
          () => TextFormField(
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Tanggal',
              prefixIcon: const Icon(Icons.calendar_today),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_drop_down),
                onPressed: () => controller.pickDate(context),
              ),
            ),
            controller: TextEditingController(
              text: controller.selectedDate.value.toString().split(' ')[0],
            ),
            onTap: () => controller.pickDate(context),
          ),
        ),
        const SizedBox(height: 16),

        // Category selector - horizontal centered icons
        const Center(
          child: Text(
            'Kategori',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 12),
        Obx(() {
          return Center(
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: controller.categories.map((cat) {
                final isSelected = controller.selectedCategory.value == cat;
                final color = _getCategoryColor(cat);
                return GestureDetector(
                  onTap: () {
                    controller.selectedCategory.value = cat;
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: isSelected ? color : color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: color,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: Icon(
                          _getCategoryIcon(cat),
                          color: isSelected ? Colors.white : color,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cat,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected ? color : null,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
        }),
        const SizedBox(height: 20),

        // Description
        TextFormField(
          controller: controller.descriptionController,
          decoration: const InputDecoration(
            labelText: 'Keterangan',
            prefixIcon: Icon(Icons.description),
            hintText: 'Contoh: Donasi dari Bapak Ahmad',
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),

        // Subject
        TextFormField(
          controller: controller.subjectController,
          decoration: const InputDecoration(
            labelText: 'Subject (Opsional)',
            prefixIcon: Icon(Icons.person),
            hintText: 'Contoh: Bapak Ahmad',
          ),
        ),
        const SizedBox(height: 80), // Space for FAB
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Cash':
        return Icons.money;
      case 'Transfer':
        return Icons.swap_horiz;
      case 'Pondok':
        return Icons.home_work;
      default:
        return Icons.attach_money;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Cash':
        return const Color(0xFF00BCD4); // Cyan
      case 'Transfer':
        return const Color(0xFF3F51B5); // Indigo
      case 'Pondok':
        return const Color(0xFF795548); // Brown
      default:
        return AppColors.incomeColor;
    }
  }
}

/// Custom TextInputFormatter untuk format ribuan dengan titik
class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (newText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final number = int.tryParse(newText);
    if (number == null) return oldValue;

    final formatter = NumberFormat('#,###', 'id_ID');
    final formatted = formatter.format(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
