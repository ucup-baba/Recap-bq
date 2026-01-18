import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/routes/app_pages.dart';
import '../../../../app/core/utils/url_launcher.dart';
import '../../../../app/data/models/memorable_model.dart';
import '../../../../app/data/services/geocoding_service.dart';
import '../memorable_controller.dart';

class MemorableHistoryView extends GetView<MemorableController> {
  const MemorableHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Riwayat Tempat',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF9C27B0), Color(0xFF5C6BC0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoadingPlaces.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.places.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_off_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Belum ada tempat tersimpan',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Simpan tempat favorit Anda dari peta',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.places.length,
          itemBuilder: (context, index) {
            final place = controller.places[index];
            return _PlaceCard(
              place: place,
              onTap: () =>
                  Get.toNamed(AppRoutes.memorableDetail, arguments: place),
              onDirections: () => _openDirections(place),
            );
          },
        );
      }),
    );
  }

  void _openDirections(MemorableModel place) {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${place.latitude},${place.longitude}';
    openUrlInNewTab(url);
  }
}

class _PlaceCard extends StatefulWidget {
  final MemorableModel place;
  final VoidCallback onTap;
  final VoidCallback onDirections;

  const _PlaceCard({
    required this.place,
    required this.onTap,
    required this.onDirections,
  });

  @override
  State<_PlaceCard> createState() => _PlaceCardState();
}

class _PlaceCardState extends State<_PlaceCard> {
  final GeocodingService _geocodingService = GeocodingService();
  String? _address;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    final address = await _geocodingService.getAddressFromCoordinates(
      widget.place.latitude,
      widget.place.longitude,
      shortFormat: false,
    );
    if (mounted) {
      setState(() => _address = address);
    }
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final accentColor = place.category.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    image: place.photoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(place.photoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: place.photoUrl == null
                      ? Icon(place.category.icon, color: accentColor, size: 32)
                      : null,
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        place.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Description
                      if (place.description != null &&
                          place.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            place.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),

                      // Address
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _address ?? 'Memuat alamat...',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Right side: Category + Direction button
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Category Icon
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        place.category.icon,
                        size: 18,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Direction Button
                    Material(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: widget.onDirections,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.directions,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
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
}
