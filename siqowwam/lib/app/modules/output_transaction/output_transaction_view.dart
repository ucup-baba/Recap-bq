import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import 'output_transaction_controller.dart';

/// Output Transaction View - For adding expense transactions
class OutputTransactionView extends GetView<OutputTransactionController> {
  const OutputTransactionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        appBar: AppBar(
          title: const Text('Input Pengeluaran'),
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
                : AppColors.expenseColor,
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
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_upward, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'PENGELUARAN',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Rp', style: TextStyle(color: Colors.white, fontSize: 24)),
          TextFormField(
            controller: controller.amountController,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [_ThousandsSeparatorInputFormatter()],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '0',
              hintStyle: TextStyle(
                color: Colors.white54,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
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

        // Category selector - centered icons (SDM first)
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
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: controller.allCategories.keys.map((cat) {
                final isSelected = controller.selectedCategory.value == cat;
                final color = _getCategoryColor(cat);
                return GestureDetector(
                  onTap: () {
                    controller.selectedCategory.value = cat;
                    final subs = controller.allCategories[cat] ?? [];
                    if (subs.isNotEmpty) {
                      controller.selectedSubcategory.value = subs.first;
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isSelected ? color : color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: color,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Icon(
                          _getCategoryIcon(cat),
                          color: isSelected ? Colors.white : color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cat,
                        style: TextStyle(
                          fontSize: 10,
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
        const SizedBox(height: 16),

        // Subcategory selector - centered wrap chips
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Sub Kategori',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 12),
        Obx(() {
          final subs =
              controller.allCategories[controller.selectedCategory.value] ?? [];
          if (subs.isEmpty) {
            return const Center(
              child: Text('Loading...', style: TextStyle(color: Colors.grey)),
            );
          }
          return Center(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: subs.map((sub) {
                final isSelected = controller.selectedSubcategory.value == sub;
                final color = _getCategoryColor(
                  controller.selectedCategory.value,
                );
                return ChoiceChip(
                  label: Text(sub),
                  selected: isSelected,
                  onSelected: (_) {
                    controller.selectedSubcategory.value = sub;
                  },
                  selectedColor: color,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : null,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
          );
        }),
        const SizedBox(height: 16),

        // Description
        TextFormField(
          controller: controller.descriptionController,
          decoration: const InputDecoration(
            labelText: 'Keterangan',
            prefixIcon: Icon(Icons.description),
            hintText: 'Contoh: Beli bensin motor',
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
            hintText: 'Contoh: Kirana',
          ),
        ),
        const SizedBox(height: 80), // Space for FAB
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'SDM':
        return Icons.people;
      case 'Pendidikan':
        return Icons.school;
      case 'Transportasi':
        return Icons.directions_car;
      case 'Fasilitas':
        return Icons.business;
      case 'Rumah Tangga':
        return Icons.home;
      case 'Lainnya':
      default:
        return Icons.more_horiz;
    }
  }

  Color _getCategoryColor(String category) {
    // SDM uses pink/magenta (unique color for admin)
    if (category == 'SDM') {
      return const Color(0xFFE91E63); // Pink
    }
    // Use same colors as user dashboard from AppConstants
    final colorValue = AppConstants.categoryColors[category];
    return colorValue != null ? Color(colorValue) : Colors.grey;
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
