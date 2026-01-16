import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/routes/app_pages.dart';
import '../../data/models/memorable_model.dart';
import 'memorable_controller.dart';

class MemorableView extends StatelessWidget {
  final bool hideHeader;

  const MemorableView({super.key, this.hideHeader = false});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is available
    if (!Get.isRegistered<MemorableController>()) {
      Get.put(MemorableController());
    }

    final controller = Get.find<MemorableController>();

    return Container(
      color: context.backgroundColor,
      child: Column(
        children: [
          // Header
          if (!hideHeader) _buildHeader(context),

          // Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.loadPlaces,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Input Card
                    _buildInputCard(context, controller),
                    // Places list removed - now accessible via header history icon
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: context.isDark
              ? [const Color(0xFFCE93D8), const Color(0xFFBA68C8)]
              : [Colors.purple.shade600, Colors.purple.shade800],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side - Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catatan Lokasi',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(Icons.bookmark_added, color: Colors.white, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'Memorable',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Right side - History icon
          Material(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Get.toNamed(AppRoutes.memorableHistory),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(
                  Icons.history_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard(BuildContext context, MemorableController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add_location_alt,
                    color: Colors.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Tambah Tempat Baru',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Name Input
            TextFormField(
              controller: controller.nameController,
              decoration: InputDecoration(
                labelText: 'Nama Tempat *',
                hintText: 'Contoh: Masjid Al-Ikhlas',
                prefixIcon: const Icon(Icons.place),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nama tempat wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description Input
            TextFormField(
              controller: controller.descriptionController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Deskripsi (Opsional)',
                hintText: 'Catatan tambahan tentang tempat ini',
                prefixIcon: const Icon(Icons.notes),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Category Selection
            Text(
              'Kategori Tempat',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 12),
            Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: MemorableCategory.values.map((category) {
                  final isSelected =
                      controller.selectedCategory.value == category;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: GestureDetector(
                      onTap: () => controller.setCategory(category),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? category.color.withValues(alpha: 0.2)
                              : Colors.grey.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? category.color
                                : Colors.grey.withValues(alpha: 0.3),
                            width: isSelected ? 2.5 : 1,
                          ),
                        ),
                        child: Icon(
                          category.icon,
                          size: 24,
                          color: isSelected
                              ? category.color
                              : context.subtextColor,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Photo Section - SIMBAQ Style
            Text(
              'Foto Tempat (Opsional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 12),
            Obx(() {
              final hasImage =
                  controller.selectedImagePath.value != null ||
                  (kIsWeb && controller.selectedImageBytes.value != null);

              if (hasImage) {
                // Image Preview with delete button
                return Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        kIsWeb
                            ? (controller.selectedImageBytes.value != null
                                  ? Image.memory(
                                      controller.selectedImageBytes.value!,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: Colors.grey.shade300,
                                      child: const Center(
                                        child: Icon(
                                          Icons.image,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ))
                            : Image.file(
                                File(controller.selectedImagePath.value!),
                                fit: BoxFit.cover,
                              ),
                        // Overlay with info
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.7),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Foto berhasil dipilih',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: controller.removeImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Camera/Gallery buttons - SIMBAQ style
              return Row(
                children: [
                  // Camera Button
                  Expanded(
                    child: _buildPhotoButton(
                      context: context,
                      icon: Icons.camera_alt_rounded,
                      label: 'Kamera',
                      onTap: () => controller.pickImage(fromCamera: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Gallery Button
                  Expanded(
                    child: _buildPhotoButton(
                      context: context,
                      icon: Icons.photo_library_rounded,
                      label: 'Galeri',
                      onTap: () => controller.pickImage(fromCamera: false),
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 20),

            // Google Maps Widget - SIMBAQ Style
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 250,
                child: Stack(
                  children: [
                    // Map
                    Obx(
                      () => GoogleMap(
                        initialCameraPosition: controller.initialCameraPosition,
                        onMapCreated: controller.setMapController,
                        onTap: controller.updateFromMap, // Tap untuk web
                        onLongPress:
                            controller.updateFromMap, // Long press untuk mobile
                        markers: controller.marker.value != null
                            ? {controller.marker.value!}
                            : {},
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                      ),
                    ),

                    // Hint overlay at top
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        color: Colors.black.withValues(alpha: 0.7),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.touch_app,
                              color: Colors.amber,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Seret marker untuk ubah lokasi',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Zoom controls
                    Positioned(
                      right: 12,
                      top: 60,
                      child: Column(
                        children: [
                          _buildMapControlButton(
                            icon: Icons.add,
                            onPressed: () {
                              controller.mapController?.animateCamera(
                                CameraUpdate.zoomIn(),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          _buildMapControlButton(
                            icon: Icons.remove,
                            onPressed: () {
                              controller.mapController?.animateCamera(
                                CameraUpdate.zoomOut(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // My location button
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: _buildMapControlButton(
                        icon: Icons.my_location,
                        onPressed: () {
                          if (controller.latitude.value != null &&
                              controller.longitude.value != null) {
                            controller.mapController?.animateCamera(
                              CameraUpdate.newLatLng(
                                LatLng(
                                  controller.latitude.value!,
                                  controller.longitude.value!,
                                ),
                              ),
                            );
                          }
                        },
                        isHighlighted: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Location Section - SIMBAQ Style
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.isDark ? const Color(0xFF2D2D2D) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: context.isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Get Current Location Button - Gradient Style
                  Obx(
                    () => _buildGradientButton(
                      context: context,
                      icon: Icons.gps_fixed_rounded,
                      label: controller.isLoadingLocation.value
                          ? 'Mencari Lokasi...'
                          : '📍 Ambil Lokasi Saat Ini',
                      isLoading: controller.isLoadingLocation.value,
                      onPressed: controller.isLoadingLocation.value
                          ? null
                          : controller.getCurrentLocation,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Check in Google Maps Button - Outlined Style
                  Obx(
                    () => _buildOutlinedButton(
                      context: context,
                      icon: Icons.map_rounded,
                      label: '🗺️ Cek di Google Maps',
                      onPressed: controller.latitude.value != null
                          ? controller.openCurrentLocationInMaps
                          : null,
                    ),
                  ),

                  // Accuracy Indicator
                  Obx(() {
                    if (controller.accuracy.value != null) {
                      return Column(
                        children: [
                          const SizedBox(height: 16),
                          _buildAccuracyIndicator(
                            context: context,
                            accuracy: controller.accuracy.value!,
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Save Button
            Obx(() {
              final isValid = controller.isFormValid;
              final isSaving = controller.isSaving.value;

              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isValid && !isSaving ? controller.savePlace : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    isSaving ? 'Menyimpan...' : 'Simpan Tempat',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// SIMBAQ-style photo button with circular icon
  Widget _buildPhotoButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final primaryColor = context.isDark
        ? const Color(0xFFCE93D8) // Light purple for dark mode
        : Colors.purple;

    return Material(
      color: context.isDark
          ? const Color(0xFF424242) // Dark surface
          : Colors.purple.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: primaryColor, size: 28),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// SIMBAQ-style gradient button (yellow/amber)
  Widget _buildGradientButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    final isEnabled = onPressed != null && !isLoading;
    const gradientColors = [
      Color(0xFFFFC107),
      Color(0xFFFF9800),
    ]; // Amber/Orange

    return Container(
      height: 56,
      decoration: isEnabled
          ? BoxDecoration(
              gradient: const LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            )
          : BoxDecoration(
              color: context.isDark
                  ? const Color(0xFF424242)
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        color: isEnabled ? Colors.black87 : Colors.grey,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: TextStyle(
                          color: isEnabled ? Colors.black87 : Colors.grey,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  /// SIMBAQ-style outlined button
  Widget _buildOutlinedButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    final isEnabled = onPressed != null;
    const primaryColor = Color(0xFFFFC107); // Amber
    final disabledColor = context.isDark
        ? Colors.grey.shade600
        : Colors.grey.shade400;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnabled ? primaryColor : disabledColor,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isEnabled ? primaryColor : disabledColor,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: isEnabled ? primaryColor : disabledColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// SIMBAQ-style accuracy indicator
  Widget _buildAccuracyIndicator({
    required BuildContext context,
    required double accuracy,
  }) {
    Color indicatorColor;
    IconData indicatorIcon;
    String statusText;

    if (accuracy < 10) {
      indicatorColor = Colors.green;
      indicatorIcon = Icons.signal_cellular_4_bar_rounded;
      statusText = '${accuracy.toStringAsFixed(1)} meter (Sangat Akurat)';
    } else if (accuracy < 50) {
      indicatorColor = Colors.blue;
      indicatorIcon = Icons.signal_cellular_alt_rounded;
      statusText = '${accuracy.toStringAsFixed(1)} meter (Akurat)';
    } else if (accuracy < 100) {
      indicatorColor = Colors.orange;
      indicatorIcon = Icons.signal_cellular_alt_2_bar_rounded;
      statusText = '${accuracy.toStringAsFixed(1)} meter (Cukup)';
    } else {
      indicatorColor = Colors.red;
      indicatorIcon = Icons.signal_cellular_alt_1_bar_rounded;
      statusText = '${accuracy.toStringAsFixed(1)} meter (Kurang Akurat)';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: indicatorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: indicatorColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: indicatorColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(indicatorIcon, color: indicatorColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Akurasi',
                  style: TextStyle(fontSize: 12, color: indicatorColor),
                ),
                const SizedBox(height: 2),
                Text(
                  statusText,
                  style: TextStyle(
                    color: indicatorColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Map control button (zoom +/-, my location)
  Widget _buildMapControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isHighlighted = false,
  }) {
    return Material(
      color: isHighlighted ? Colors.amber : Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(8),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            color: isHighlighted ? Colors.white : Colors.grey.shade700,
            size: 24,
          ),
        ),
      ),
    );
  }
}
