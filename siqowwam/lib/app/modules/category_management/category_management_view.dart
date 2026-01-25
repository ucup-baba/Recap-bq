import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/category_service.dart';
import '../../core/constants/app_constants.dart';

/// Category Management View for Super Admin
class CategoryManagementView extends StatefulWidget {
  const CategoryManagementView({super.key});

  @override
  State<CategoryManagementView> createState() => _CategoryManagementViewState();
}

class _CategoryManagementViewState extends State<CategoryManagementView> {
  final CategoryService _categoryService = CategoryService();
  final _addController = TextEditingController();

  Map<String, List<String>> _categories = {};
  String? _selectedCategory;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      // Initialize default data if not exists
      await _categoryService.initializeDefaultSubcategories();
      // Load categories
      _categories = await _categoryService.getAllCategoriesWithSubcategories();
    } catch (e) {
      debugPrint('Error loading categories: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
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
    final colorValue = AppConstants.categoryColors[category];
    return colorValue != null ? Color(colorValue) : Colors.deepPurple;
  }

  void _showAddSubcategoryDialog() {
    if (_selectedCategory == null) return;
    _addController.clear();

    Get.dialog(
      AlertDialog(
        title: Text('Tambah Sub-kategori $_selectedCategory'),
        content: TextField(
          controller: _addController,
          decoration: const InputDecoration(
            labelText: 'Nama Sub-kategori',
            hintText: 'Contoh: Listrik',
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final name = _addController.text.trim();
              if (name.isEmpty) {
                Get.snackbar('Error', 'Nama tidak boleh kosong');
                return;
              }

              Get.back();
              final success = await _categoryService.addSubcategory(
                _selectedCategory!,
                name,
              );

              if (success) {
                Get.snackbar('Sukses', 'Sub-kategori berhasil ditambahkan');
                _loadCategories();
              } else {
                Get.snackbar('Error', 'Gagal menambahkan sub-kategori');
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(String subcategory) {
    if (_selectedCategory == null) return;
    _addController.text = subcategory;

    Get.dialog(
      AlertDialog(
        title: const Text('Edit Sub-kategori'),
        content: TextField(
          controller: _addController,
          decoration: const InputDecoration(labelText: 'Nama Sub-kategori'),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final newName = _addController.text.trim();
              if (newName.isEmpty) {
                Get.snackbar('Error', 'Nama tidak boleh kosong');
                return;
              }

              Get.back();
              final success = await _categoryService.renameSubcategory(
                _selectedCategory!,
                subcategory,
                newName,
              );

              if (success) {
                Get.snackbar('Sukses', 'Sub-kategori berhasil diubah');
                _loadCategories();
              } else {
                Get.snackbar('Error', 'Gagal mengubah sub-kategori');
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String subcategory) {
    if (_selectedCategory == null) return;

    Get.dialog(
      AlertDialog(
        title: const Text('Hapus Sub-kategori'),
        content: Text('Yakin ingin menghapus "$subcategory"?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Get.back();
              final success = await _categoryService.removeSubcategory(
                _selectedCategory!,
                subcategory,
              );

              if (success) {
                Get.snackbar('Sukses', 'Sub-kategori berhasil dihapus');
                _loadCategories();
              } else {
                Get.snackbar('Error', 'Gagal menghapus sub-kategori');
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _syncRoles() async {
    setState(() => _isLoading = true);
    try {
      final count = await _categoryService.syncRoleSubcategories();
      if (count > 0) {
        Get.snackbar(
          'Sukses',
          '$count role berhasil disinkronkan',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Info',
          'Tidak ada role yang perlu disinkronkan',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal sinkronisasi: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Kategori'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sinkronkan sub-kategori ke semua Role',
            onPressed: _isLoading ? null : _syncRoles,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Fixed categories row
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kategori (Fixed)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _categoryService.fixedCategories.map((cat) {
                          final isSelected = _selectedCategory == cat;
                          final color = _getCategoryColor(cat);

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = cat;
                              });
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? color
                                        : color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: color,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(cat),
                                    color: isSelected ? Colors.white : color,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  cat,
                                  style: TextStyle(
                                    fontSize: 11,
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
                    ],
                  ),
                ),
                const Divider(),
                // Subcategories list
                Expanded(
                  child: _selectedCategory == null
                      ? const Center(
                          child: Text(
                            'Pilih kategori untuk melihat sub-kategori',
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Sub-kategori $_selectedCategory',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  IconButton(
                                    onPressed: _showAddSubcategoryDialog,
                                    icon: const Icon(Icons.add_circle),
                                    color: _getCategoryColor(
                                      _selectedCategory!,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child:
                                  _categories[_selectedCategory]?.isEmpty ??
                                      true
                                  ? const Center(
                                      child: Text('Belum ada sub-kategori'),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      itemCount:
                                          _categories[_selectedCategory]
                                              ?.length ??
                                          0,
                                      itemBuilder: (context, index) {
                                        final sub =
                                            _categories[_selectedCategory]![index];
                                        return Card(
                                          child: ListTile(
                                            leading: Icon(
                                              Icons.subdirectory_arrow_right,
                                              color: _getCategoryColor(
                                                _selectedCategory!,
                                              ),
                                            ),
                                            title: Text(sub),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.edit,
                                                    size: 20,
                                                  ),
                                                  onPressed: () =>
                                                      _showEditDialog(sub),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    size: 20,
                                                  ),
                                                  color: Colors.red,
                                                  onPressed: () =>
                                                      _showDeleteDialog(sub),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }
}
