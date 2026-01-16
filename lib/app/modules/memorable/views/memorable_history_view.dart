import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/date_utils.dart';
import '../../../../app/data/models/memorable_model.dart';
import '../../../../app/data/services/geocoding_service.dart';
import '../memorable_controller.dart';

class MemorableHistoryView extends GetView<MemorableController> {
  const MemorableHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Tempat',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: true,
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
                Icon(Icons.location_off, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Belum ada tempat tersimpan',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
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
              onDelete: () => _confirmDelete(context, place),
              onTap: () {
                Get.back();
                controller.focusOnLocation(place.latitude, place.longitude);
              },
            );
          },
        );
      }),
    );
  }

  void _confirmDelete(BuildContext context, MemorableModel place) {
    Get.dialog(
      AlertDialog(
        title: const Text('Hapus Tempat'),
        content: Text('Yakin ingin menghapus "${place.name}"?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Get.back();
              Get.find<MemorableController>().deletePlace(place);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// Separate StatefulWidget to handle async address loading
class _PlaceCard extends StatefulWidget {
  final MemorableModel place;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _PlaceCard({
    required this.place,
    required this.onDelete,
    required this.onTap,
  });

  @override
  State<_PlaceCard> createState() => _PlaceCardState();
}

class _PlaceCardState extends State<_PlaceCard> {
  final GeocodingService _geocodingService = GeocodingService();
  String? _address;
  bool _isLoadingAddress = true;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    final address = await _geocodingService.getAddressFromCoordinates(
      widget.place.latitude,
      widget.place.longitude,
      shortFormat: false, // Show full address: desa, kecamatan, kabupaten
    );
    if (mounted) {
      setState(() {
        _address = address;
        _isLoadingAddress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: place.photoUrl != null
              ? Image.network(
                  place.photoUrl!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(
                    width: 50,
                    height: 50,
                    color: Colors.grey.shade100,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                )
              : Container(
                  width: 50,
                  height: 50,
                  color: place.category.color.withValues(alpha: 0.2),
                  child: Icon(place.category.icon, color: place.category.color),
                ),
        ),
        title: Row(
          children: [
            Icon(place.category.icon, size: 14, color: place.category.color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                place.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            // Address display with loading state
            Row(
              children: [
                Icon(Icons.location_on, size: 12, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: _isLoadingAddress
                      ? Row(
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Memuat alamat...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          _address ?? place.formattedCoordinates,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              AppDateUtils.formatDateTime(place.createdAt),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
          onPressed: widget.onDelete,
        ),
        onTap: widget.onTap,
      ),
    );
  }
}
