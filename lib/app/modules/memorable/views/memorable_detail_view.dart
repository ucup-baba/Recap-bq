import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../app/core/routes/app_pages.dart';
import '../../../../app/core/utils/date_utils.dart';
import '../../../../app/core/utils/url_launcher.dart';
import '../../../../app/data/models/memorable_model.dart';
import '../../../../app/data/services/geocoding_service.dart';
import '../memorable_controller.dart';

class MemorableDetailView extends StatefulWidget {
  const MemorableDetailView({super.key});

  @override
  State<MemorableDetailView> createState() => _MemorableDetailViewState();
}

class _MemorableDetailViewState extends State<MemorableDetailView> {
  final GeocodingService _geocodingService = GeocodingService();
  late MemorableModel place;
  String? _address;
  bool _isLoadingAddress = true;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args == null || args is! MemorableModel) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.back();
      });
      return;
    }
    place = args;
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    final address = await _geocodingService.getAddressFromCoordinates(
      place.latitude,
      place.longitude,
      shortFormat: false,
    );
    if (mounted) {
      setState(() {
        _address = address;
        _isLoadingAddress = false;
      });
    }
  }

  void _openDirections() {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${place.latitude},${place.longitude}';
    openUrlInNewTab(url);
  }

  void _focusOnMap() {
    // Buka Google Maps eksternal untuk melihat lokasi
    final url =
        'https://www.google.com/maps/search/?api=1&query=${place.latitude},${place.longitude}';
    openUrlInNewTab(url);
  }

  void _confirmDelete() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Tempat'),
        content: Text('Yakin ingin menghapus "${place.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.find<MemorableController>().deletePlace(place);
              Get.back();
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _editPlace() {
    Get.toNamed(AppRoutes.memorableEdit, arguments: place);
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'Disalin',
      'Koordinat berhasil disalin',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = place.category.color;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Hero Image AppBar
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            stretch: true,
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                onPressed: _editPlace,
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit',
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') _confirmDelete();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        SizedBox(width: 12),
                        Text('Hapus', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image or placeholder
                  place.photoUrl != null
                      ? Image.network(
                          place.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            color: accentColor,
                            child: Icon(
                              place.category.icon,
                              size: 80,
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                        )
                      : Container(
                          color: accentColor,
                          child: Center(
                            child: Icon(
                              place.category.icon,
                              size: 100,
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                        ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                          Colors.black.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                  // Curved white bottom overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content Sheet
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar (drag indicator)
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 14),
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category & Date row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    place.category.icon,
                                    size: 14,
                                    color: accentColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    place.category.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: accentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              AppDateUtils.formatDateTime(place.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          place.name,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3142),
                            height: 1.2,
                          ),
                        ),

                        // Description
                        if (place.description != null &&
                            place.description!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            place.description!,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade600,
                              height: 1.6,
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),

                        // Lokasi Section
                        const Text(
                          'Lokasi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Address Card
                        _buildInfoCard(
                          icon: Icons.location_on_outlined,
                          iconColor: Colors.blue,
                          title: 'Alamat Lengkap',
                          content: _isLoadingAddress
                              ? 'Memuat alamat...'
                              : (_address ?? 'Alamat tidak tersedia'),
                          isLoading: _isLoadingAddress,
                        ),
                        const SizedBox(height: 12),

                        // Coordinates Card
                        _buildInfoCard(
                          icon: Icons.my_location,
                          iconColor: Colors.blue,
                          title: 'Koordinat GPS',
                          content: place.formattedCoordinates,
                          trailing: IconButton(
                            onPressed: () =>
                                _copyToClipboard(place.formattedCoordinates),
                            icon: Icon(
                              Icons.copy_rounded,
                              size: 18,
                              color: Colors.grey.shade400,
                            ),
                            tooltip: 'Salin',
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _focusOnMap,
                                icon: const Icon(Icons.map_outlined, size: 20),
                                label: const Text('Lokasi'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(color: Colors.grey.shade300),
                                  foregroundColor: const Color(0xFF2D3142),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _openDirections,
                                icon: const Icon(Icons.near_me, size: 20),
                                label: const Text('Rute'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
    bool isLoading = false,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 4),
                isLoading
                    ? Row(
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            content,
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        content,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2D3142),
                          height: 1.4,
                        ),
                      ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
