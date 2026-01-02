import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import 'report_input_controller.dart';

class ReportInputView extends GetView<ReportInputController> {
  const ReportInputView({super.key});

  // Helper function untuk mendapatkan warna avatar berdasarkan nama
  // Menggunakan hash untuk konsistensi warna
  Color _getAvatarColor(String name) {
    final avatarColors = [
      const Color(0xFF2196F3), // Blue
      const Color(0xFFE53935), // Red
      const Color(0xFFFFB300), // Yellow/Orange
      const Color(0xFF8E24AA), // Purple
      const Color(0xFF4CAF50), // Green
      const Color(0xFFFF6F00), // Deep Orange
      const Color(0xFF00ACC1), // Cyan
      const Color(0xFFE91E63), // Pink
    ];
    final hash = name.hashCode;
    return avatarColors[hash.abs() % avatarColors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.only(
              top: 40,
              bottom: 20,
              left: 16,
              right: 16,
            ),
            decoration: BoxDecoration(
              gradient: AppColors.getHeaderGradient(context),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Input Laporan',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      Text(
                        controller.area,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: Obx(() {
              final currentStatus = controller.status.value;
              String statusText;
              IconData statusIcon;
              Color statusColor;

              switch (currentStatus) {
                case AppConstants.reportStatusPending:
                  statusText = 'Pending - Menunggu verifikasi oleh admin';
                  statusIcon = Icons.hourglass_top;
                  statusColor = AppColors.primaryBlue;
                  break;
                case AppConstants.reportStatusVerified:
                  statusText = 'Terverifikasi';
                  statusIcon = Icons.check_circle;
                  statusColor = AppColors.successGreen;
                  break;
                case AppConstants.reportStatusRejected:
                  statusText = 'Ditolak - Silakan perbaiki dan kirim ulang';
                  statusIcon = Icons.cancel;
                  statusColor = AppColors.alertRed;
                  break;
                case AppConstants.reportStatusDraft:
                default:
                  statusText = 'Draft - Belum dikirim';
                  statusIcon = Icons.edit_note;
                  statusColor = AppColors.primaryBlue;
                  break;
              }

              return Column(
                children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(statusIcon, color: statusColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: context.textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Photo Evidence Section
                  _buildPhotoEvidence(context),

                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: controller.tasks.length,
                      itemBuilder: (context, index) {
                        final task = controller.tasks[index];
                        final isDone = task.isDone;

                        return Obx(() {
                          // Wrap dengan Obx agar onTap reactive terhadap isReadOnly
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: context.cardColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: controller.isReadOnly.value
                                  ? null
                                  : () => controller.toggleDone(index),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Custom Checkbox Icon
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isDone
                                            ? AppColors.successGreen
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: isDone
                                              ? AppColors.successGreen
                                              : Colors.grey[300]!,
                                          width: 2,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.check,
                                        size: 16,
                                        color: isDone
                                            ? Colors.white
                                            : Colors.transparent,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            task.taskName,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: isDone
                                                  ? context.textColor
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                          if (task.executors.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 6,
                                              ),
                                              child: Wrap(
                                                spacing: 6,
                                                runSpacing: 4,
                                                children: task.executors.map((
                                                  executor,
                                                ) {
                                                  return Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: _getAvatarColor(
                                                        executor,
                                                      ).withValues(alpha: 0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      border: Border.all(
                                                        color: _getAvatarColor(
                                                          executor,
                                                        ),
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Container(
                                                          width: 16,
                                                          height: 16,
                                                          decoration: BoxDecoration(
                                                            color:
                                                                _getAvatarColor(
                                                                  executor,
                                                                ),
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                          child: Center(
                                                            child: Text(
                                                              executor[0]
                                                                  .toUpperCase(),
                                                              style: const TextStyle(
                                                                fontSize: 8,
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          executor,
                                                          style: TextStyle(
                                                            color:
                                                                _getAvatarColor(
                                                                  executor,
                                                                ),
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            )
                                          else if (!controller.isReadOnly.value)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 6,
                                              ),
                                              child: Text(
                                                'Tap untuk pilih pelaksana',
                                                style: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: 12,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        });
                      },
                    ),
                  ),
                ],
              );
            }),
          ),

          // Tombol Simpan dan Batal
          Obx(
            () => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    // Tombol Batal
                    Expanded(
                      child: OutlinedButton(
                        onPressed: controller.isSubmitting.value
                            ? null
                            : () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          'Batal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.textColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Tombol Simpan
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed:
                            controller.isReadOnly.value ||
                                controller.isSubmitting.value
                            ? null
                            : controller.submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: controller.isSubmitting.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Simpan',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoEvidence(BuildContext context) {
    return Obx(() {
      final photos = controller.photoUrls;
      final isUploading = controller.isUploadingPhoto.value;
      final isReadOnly = controller.isReadOnly.value;
      final canAddMore = controller.canAddMorePhotos;

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.photo_library,
                      color: AppColors.primaryBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Foto Bukti',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  // Photo counter
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: photos.isEmpty
                          ? Colors.grey.shade100
                          : AppColors.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${photos.length}/${ReportInputController.maxPhotos}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: photos.isEmpty
                            ? Colors.grey
                            : AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Photo gallery - Horizontal scroll
            if (isUploading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (photos.isEmpty && isReadOnly)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Tidak ada foto',
                      style: TextStyle(color: context.subtextColor),
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: 110,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    // Existing photos
                    ...photos.asMap().entries.map((entry) {
                      final index = entry.key;
                      final url = entry.value;
                      return _buildPhotoItem(context, url, index, isReadOnly);
                    }),
                    // Add photo button
                    if (!isReadOnly && canAddMore)
                      _buildAddPhotoButton(context),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildPhotoItem(
    BuildContext context,
    String url,
    int index,
    bool isReadOnly,
  ) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: url,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.error, color: Colors.red),
              ),
            ),
          ),
          // Delete button
          if (!isReadOnly)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => controller.deletePhoto(index),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddPhotoButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPhotoPickerDialog(context),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryBlue,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, size: 32, color: AppColors.primaryBlue),
            SizedBox(height: 8),
            Text(
              'Tambah',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoPickerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Sumber Foto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () {
                Get.back();
                controller.pickPhotoFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () {
                Get.back();
                controller.pickPhotoFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }
}
