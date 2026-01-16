import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/data/services/location_service.dart';
import '../../domain/entities/memorable_place.dart';
import '../../domain/usecases/delete_place_usecase.dart';
import '../../domain/usecases/load_places_usecase.dart';
import '../../domain/usecases/save_place_usecase.dart';

/// Memorable Controller (Clean Architecture)
/// Uses use cases instead of direct Firebase calls
class MemorableController extends GetxController {
  // Dependencies (injected)
  final SavePlaceUseCase savePlaceUseCase;
  final LoadPlacesUseCase loadPlacesUseCase;
  final DeletePlaceUseCase deletePlaceUseCase;
  final String currentUserId; // Injected from FirebaseAuth

  // Services
  final LocationService _locationService = LocationService();
  final ImagePicker _imagePicker = ImagePicker();

  MemorableController({
    required this.savePlaceUseCase,
    required this.loadPlacesUseCase,
    required this.deletePlaceUseCase,
    required this.currentUserId,
  });

  // Text controllers
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();

  // Google Maps
  GoogleMapController? mapController;
  final marker = Rxn<Marker>();

  // Default position (Panti Asuhan Baitul Qowwam)
  static const defaultLatLng = LatLng(-6.1636608, 106.938368);
  static const defaultZoomLevel = 16.0;

  CameraPosition get initialCameraPosition => CameraPosition(
    target: latitude.value != null && longitude.value != null
        ? LatLng(latitude.value!, longitude.value!)
        : defaultLatLng,
    zoom: defaultZoomLevel,
  );

  // Reactive state
  final latitude = Rxn<double>();
  final longitude = Rxn<double>();
  final accuracy = Rxn<double>();
  final selectedCategory = Rx<MemorableCategory>(MemorableCategory.wisata);
  final selectedImagePath = Rxn<String>();
  final selectedImageBytes = Rxn<Uint8List>();
  final photoFile = Rxn<dynamic>(); // File for mobile, Uint8List for web
  final isLoadingLocation = false.obs;
  final isSaving = false.obs;
  final places = <MemorablePlace>[].obs;
  final isLoadingPlaces = false.obs;
  final rxName = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadPlaces();
    nameController.addListener(() {
      rxName.value = nameController.text;
    });
  }

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  /// Check if form is valid
  bool get isFormValid =>
      rxName.value.isNotEmpty &&
      latitude.value != null &&
      longitude.value != null;

  /// Set category
  void setCategory(MemorableCategory category) {
    selectedCategory.value = category;
  }

  /// Set map controller
  void setMapController(GoogleMapController controller) {
    mapController = controller;
  }

  /// Update marker position
  void updateMarker(LatLng position) {
    marker.value = Marker(
      markerId: const MarkerId('selected_location'),
      position: position,
      draggable: true,
      onDragEnd: _onMarkerDragEnd,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: const InfoWindow(title: 'Seret untuk pindahkan'),
    );
    latitude.value = position.latitude;
    longitude.value = position.longitude;
  }

  /// Handle marker drag end
  void _onMarkerDragEnd(LatLng newPosition) {
    latitude.value = newPosition.latitude;
    longitude.value = newPosition.longitude;
    marker.value = Marker(
      markerId: const MarkerId('selected_location'),
      position: newPosition,
      draggable: true,
      onDragEnd: _onMarkerDragEnd,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: const InfoWindow(title: 'Seret untuk pindahkan'),
    );
    Get.snackbar(
      '📍 Lokasi Diperbarui',
      'Lat: ${newPosition.latitude.toStringAsFixed(6)}, Lng: ${newPosition.longitude.toStringAsFixed(6)}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  /// Update location from map long press
  void updateFromMap(LatLng position) {
    updateMarker(position);
    Get.snackbar(
      '📍 Lokasi Diperbarui',
      'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  /// Pick image from gallery or camera
  Future<void> pickImage({bool fromCamera = false}) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        selectedImagePath.value = pickedFile.path;
        if (kIsWeb) {
          // Web: store bytes
          final bytes = await pickedFile.readAsBytes();
          selectedImageBytes.value = bytes;
          photoFile.value = bytes;
        } else {
          // Mobile: use path (repository will handle File creation)
          photoFile.value = pickedFile.path;
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      Get.snackbar(
        'Gagal',
        'Tidak dapat mengambil foto',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    }
  }

  /// Remove selected image
  void removeImage() {
    selectedImagePath.value = null;
    selectedImageBytes.value = null;
    photoFile.value = null;
  }

  /// Get current GPS location
  Future<void> getCurrentLocation() async {
    isLoadingLocation.value = true;

    final result = await _locationService.getCurrentPositionWithError();

    if (result.isSuccess && result.position != null) {
      latitude.value = result.position!.latitude;
      longitude.value = result.position!.longitude;
      accuracy.value = result.position!.accuracy;

      final newPosition = LatLng(latitude.value!, longitude.value!);
      updateMarker(newPosition);

      mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(newPosition, defaultZoomLevel),
      );

      Get.snackbar(
        'Lokasi Ditemukan',
        'Akurasi: ${_locationService.getAccuracyString(accuracy.value)}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } else if (result.error != null) {
      final errorMessage = _locationService.getErrorMessage(result.error!);
      Get.snackbar(
        'Gagal Mendapatkan Lokasi',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );

      if (result.error == LocationError.permissionDeniedForever) {
        Get.dialog(
          AlertDialog(
            title: const Text('Izin Lokasi Diperlukan'),
            content: const Text(
              'Untuk menggunakan fitur ini, mohon izinkan akses lokasi di pengaturan aplikasi.',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  Get.back();
                  _locationService.openAppSettings();
                },
                child: const Text('Buka Pengaturan'),
              ),
            ],
          ),
        );
      }
    }

    isLoadingLocation.value = false;
  }

  /// Load places using use case
  Future<void> loadPlaces() async {
    isLoadingPlaces.value = true;

    try {
      final loadedPlaces = await loadPlacesUseCase();
      places.value = loadedPlaces;
    } catch (e) {
      debugPrint('Error loading places: $e');
      Get.snackbar(
        'Gagal Memuat Data',
        'Terjadi kesalahan saat memuat tempat memorable',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    }

    isLoadingPlaces.value = false;
  }

  /// Save place using use case
  Future<void> savePlace() async {
    if (!isFormValid) return;

    isSaving.value = true;

    try {
      await savePlaceUseCase(
        name: nameController.text.trim(),
        latitude: latitude.value!,
        longitude: longitude.value!,
        category: selectedCategory.value,
        createdBy: currentUserId,
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        accuracy: accuracy.value,
        photoFile: photoFile.value,
      );

      Get.snackbar(
        'Berhasil Disimpan! 🎉',
        '${nameController.text} telah ditambahkan ke daftar tempat memorable',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      _resetForm();
      await loadPlaces();
    } catch (e) {
      debugPrint('Error saving place: $e');
      Get.snackbar(
        'Gagal Menyimpan',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    }

    isSaving.value = false;
  }

  /// Delete place using use case
  Future<void> deletePlace(MemorablePlace place) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Hapus Tempat?'),
        content: Text('Yakin ingin menghapus "${place.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await deletePlaceUseCase(place.id, photoUrl: place.photoUrl);

      places.removeWhere((p) => p.id == place.id);

      Get.snackbar(
        'Berhasil Dihapus',
        '${place.name} telah dihapus',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade600,
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('Error deleting place: $e');
      Get.snackbar(
        'Gagal Menghapus',
        'Terjadi kesalahan. Mohon coba lagi.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    }
  }

  /// Reset form fields
  void _resetForm() {
    nameController.clear();
    descriptionController.clear();
    latitude.value = null;
    longitude.value = null;
    accuracy.value = null;
    selectedCategory.value = MemorableCategory.wisata;
    selectedImagePath.value = null;
    selectedImageBytes.value = null;
    photoFile.value = null;
  }

  /// Open location in Google Maps
  void openInMaps(MemorablePlace place) {
    Get.snackbar(
      'Koordinat',
      place.formattedCoordinates,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 5),
    );
  }

  /// Open current form location
  void openCurrentLocationInMaps() {
    if (latitude.value != null && longitude.value != null) {
      Get.snackbar(
        '📍 Koordinat Lokasi',
        '${latitude.value!.toStringAsFixed(6)}, ${longitude.value!.toStringAsFixed(6)}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.amber,
        colorText: Colors.black87,
      );
    }
  }
}
