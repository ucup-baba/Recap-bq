import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import 'role_controller.dart';

/// Role Form View - Add/Edit role with icon picker and category selector
class RoleFormView extends GetView<RoleController> {
  const RoleFormView({super.key});

  @override
  Widget build(BuildContext context) {
    final isEditing = controller.selectedRole.value != null;
    final nameTextController = TextEditingController(
      text: controller.nameController.value,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Role' : 'Tambah Role'),
        backgroundColor: AppColors.primaryLight,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Role Name
            _buildSectionTitle('Nama Role'),
            const SizedBox(height: 8),
            TextFormField(
              controller: nameTextController,
              decoration: InputDecoration(
                hintText: 'Contoh: Pengasuh Putra',
                prefixIcon: const Icon(Icons.badge),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => controller.nameController.value = value,
            ),
            const SizedBox(height: 24),

            // Icon Picker
            _buildSectionTitle('Pilih Icon'),
            const SizedBox(height: 8),
            _buildIconPicker(context),
            const SizedBox(height: 24),

            // Color Picker
            _buildSectionTitle('Pilih Warna'),
            const SizedBox(height: 8),
            _buildColorPicker(context),
            const SizedBox(height: 24),

            // Category Selector
            _buildSectionTitle('Kategori Pengeluaran'),
            const SizedBox(height: 8),
            _buildCategorySelector(context),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: Obx(
        () => FloatingActionButton.extended(
          onPressed: controller.isLoading.value
              ? null
              : () async {
                  final success = await controller.saveRole();
                  debugPrint('Save result: $success');
                  if (success) {
                    // Close any open snackbars first
                    Get.closeCurrentSnackbar();

                    // Navigate back after current frame
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      debugPrint('Post frame callback - navigating back');
                      Get.back();
                    });
                  }
                },
          backgroundColor: controller.isLoading.value
              ? Colors.grey
              : AppColors.primaryLight,
          icon: controller.isLoading.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.save),
          label: Text(isEditing ? 'Simpan Perubahan' : 'Simpan Role'),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildIconPicker(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Obx(
        () => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppConstants.availableIcons.entries.map((entry) {
            final iconFileName = entry.key;
            final isSelected = controller.selectedIconName.value == entry.key;
            final selectedColor = Color(controller.selectedIconColor.value);

            return InkWell(
              onTap: () => controller.selectedIconName.value = entry.key,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isSelected
                      ? selectedColor.withValues(alpha: 0.2)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: selectedColor, width: 2)
                      : null,
                ),
                child: Tooltip(
                  message: entry.value,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: SvgPicture.asset(
                      'assets/icons/$iconFileName.svg',
                      colorFilter: ColorFilter.mode(
                        isSelected ? selectedColor : Colors.grey.shade600,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildColorPicker(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Obx(
        () => Wrap(
          spacing: 12,
          runSpacing: 12,
          children: AppConstants.availableColors.entries.map((entry) {
            final color = Color(entry.key);
            final isSelected = controller.selectedIconColor.value == entry.key;

            return InkWell(
              onTap: () => controller.selectedIconColor.value = entry.key,
              borderRadius: BorderRadius.circular(24),
              child: Tooltip(
                message: entry.value,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCategorySelector(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      child: Obx(
        () => Column(
          children: AppConstants.expenseCategories.keys.map((category) {
            // Get subcategories from Firestore via controller
            final subcategories = controller.getSubcategories(category);
            final isCategorySelected = controller.isCategorySelected(category);

            // Get category color
            final categoryColor = Color(
              AppConstants.categoryColors[category] ?? 0xFF607D8B,
            );

            return ExpansionTile(
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: isCategorySelected,
                    onChanged: (_) =>
                        controller.toggleCategory(category, subcategories),
                    activeColor: categoryColor,
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(category),
                      color: categoryColor,
                      size: 20,
                    ),
                  ),
                ],
              ),
              title: Text(
                category,
                style: TextStyle(
                  fontWeight: isCategorySelected
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: isCategorySelected
                      ? categoryColor
                      : Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              initiallyExpanded: isCategorySelected,
              children: subcategories.map((sub) {
                final isSubSelected = controller.isSubcategorySelected(
                  category,
                  sub,
                );
                return ListTile(
                  contentPadding: const EdgeInsets.only(left: 72, right: 16),
                  leading: Checkbox(
                    value: isSubSelected,
                    onChanged: (_) =>
                        controller.toggleSubcategory(category, sub),
                    activeColor: categoryColor,
                  ),
                  title: Text(
                    sub,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  dense: true,
                );
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Helper function to get category icon
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Pendidikan':
        return Icons.menu_book_rounded;
      case 'Transportasi':
        return Icons.local_shipping_rounded;
      case 'Fasilitas':
        return Icons.apartment_rounded;
      case 'Rumah Tangga':
        return Icons.cottage_rounded;
      case 'Lainnya':
      default:
        return Icons.more_horiz_rounded;
    }
  }
}
