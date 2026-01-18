import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/memorable_model.dart';
import '../../data/services/location_service.dart';

class MemorableController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final LocationService _locationService = LocationService();
  final ImagePicker _imagePicker = ImagePicker();

  // Text controllers
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();

  // Form key
  final formKey = GlobalKey<FormState>();

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
  final isLoadingLocation = false.obs;
  final isUploadingPhoto = false.obs;
  final isSaving = false.obs;
  final places = <MemorableModel>[].obs;
  final isLoadingPlaces = false.obs;
  final rxName = ''.obs; // Reactive name for form validation

  @override
  void onInit() {
    super.onInit();
    loadPlaces();
    // Listen to name changes for form validation
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

  /// Get current user ID
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  /// Check if form is valid (uses reactive values for Obx)
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
      draggable: true, // Enable drag
      onDragEnd: _onMarkerDragEnd, // Handle drag end
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
    // Update marker with new position
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
        // For web, store bytes
        if (kIsWeb) {
          selectedImageBytes.value = await pickedFile.readAsBytes();
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
  }

  /// Upload photo to Firebase Storage
  Future<String?> _uploadPhoto() async {
    debugPrint('📸 _uploadPhoto: Starting upload...');
    debugPrint('📸 selectedImagePath: ${selectedImagePath.value}');
    debugPrint(
      '📸 selectedImageBytes: ${selectedImageBytes.value != null ? "${selectedImageBytes.value!.length} bytes" : "null"}',
    );

    if (selectedImagePath.value == null && selectedImageBytes.value == null) {
      debugPrint('📸 _uploadPhoto: No image to upload');
      return null;
    }

    isUploadingPhoto.value = true;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'memorable_${currentUserId}_$timestamp.jpg';
      final ref = _storage.ref().child('memorable_photos').child(fileName);

      UploadTask uploadTask;
      if (kIsWeb && selectedImageBytes.value != null) {
        uploadTask = ref.putData(
          selectedImageBytes.value!,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        uploadTask = ref.putFile(
          File(selectedImagePath.value!),
          SettableMetadata(contentType: 'image/jpeg'),
        );
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('📸 _uploadPhoto: Success! URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('📸 Error uploading photo: $e');
      return null;
    } finally {
      isUploadingPhoto.value = false;
    }
  }

  /// Get current GPS location
  Future<void> getCurrentLocation() async {
    isLoadingLocation.value = true;

    final result = await _locationService.getCurrentPositionWithError();

    if (result.isSuccess && result.position != null) {
      latitude.value = result.position!.latitude;
      longitude.value = result.position!.longitude;
      accuracy.value = result.position!.accuracy;

      // Update marker on map
      final newPosition = LatLng(latitude.value!, longitude.value!);
      updateMarker(newPosition);

      // Animate camera to new position
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
      // Offer to open settings if permission denied forever
      if (result.error == LocationError.permissionDeniedForever) {
        final errorMessage = _locationService.getErrorMessage(result.error!);
        Get.snackbar(
          'Izin Lokasi Ditolak',
          errorMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade600,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
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
      } else {
        // For other errors, offer manual coordinate entry as fallback (without error snackbar)
        _showManualLocationDialog();
      }
    }

    isLoadingLocation.value = false;
  }

  /// Show dialog for manual coordinate entry when GPS fails
  void _showManualLocationDialog() {
    final latController = TextEditingController(text: '-7.6772');
    final lngController = TextEditingController(text: '110.3234');

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.location_searching, color: Colors.orange),
            SizedBox(width: 12),
            Text('Lokasi Manual'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'GPS tidak bisa diakses. Masukkan koordinat secara manual:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: latController,
              decoration: InputDecoration(
                labelText: 'Latitude',
                hintText: 'Contoh: -7.6772',
                prefixIcon: const Icon(Icons.north),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lngController,
              decoration: InputDecoration(
                labelText: 'Longitude',
                hintText: 'Contoh: 110.3234',
                prefixIcon: const Icon(Icons.east),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
            ),
            const SizedBox(height: 12),
            // Quick location buttons
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('Yogyakarta'),
                  avatar: const Icon(Icons.location_city, size: 16),
                  onPressed: () {
                    latController.text = '-7.7956';
                    lngController.text = '110.3695';
                  },
                ),
                ActionChip(
                  label: const Text('Jakarta'),
                  avatar: const Icon(Icons.location_city, size: 16),
                  onPressed: () {
                    latController.text = '-6.2088';
                    lngController.text = '106.8456';
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final lat = double.tryParse(latController.text);
              final lng = double.tryParse(lngController.text);

              if (lat != null && lng != null) {
                latitude.value = lat;
                longitude.value = lng;
                accuracy.value = 0; // Manual entry has no accuracy

                final newPosition = LatLng(lat, lng);
                updateMarker(newPosition);
                mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(newPosition, defaultZoomLevel),
                );

                Get.back();
                Get.snackbar(
                  'Lokasi Diatur',
                  'Koordinat: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green.shade600,
                  colorText: Colors.white,
                );
              } else {
                Get.snackbar(
                  'Format Salah',
                  'Masukkan koordinat yang valid',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.orange,
                  colorText: Colors.white,
                );
              }
            },
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Terapkan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Load places from Firestore
  Future<void> loadPlaces() async {
    if (currentUserId == null) return;

    isLoadingPlaces.value = true;

    try {
      final snapshot = await _firestore
          .collection('memorable_places')
          .where('createdBy', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .get();

      places.value = snapshot.docs
          .map((doc) => MemorableModel.fromFirestore(doc))
          .toList();

      // Debug: Log loaded places with photoUrl
      for (var place in places) {
        debugPrint(
          '📋 Loaded place: ${place.name}, photoUrl: ${place.photoUrl}',
        );
      }
    } catch (e) {
      debugPrint('Error loading places: $e');
      // If index not ready, try without ordering
      try {
        final snapshot = await _firestore
            .collection('memorable_places')
            .where('createdBy', isEqualTo: currentUserId)
            .get();

        final loadedPlaces = snapshot.docs
            .map((doc) => MemorableModel.fromFirestore(doc))
            .toList();
        // Sort locally
        loadedPlaces.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        places.value = loadedPlaces;
      } catch (e2) {
        debugPrint('Error loading places (fallback): $e2');
      }
    }

    isLoadingPlaces.value = false;
  }

  /// Save a new place
  Future<void> savePlace() async {
    if (!isFormValid || currentUserId == null) return;

    isSaving.value = true;

    try {
      // Upload photo if selected
      String? photoUrl;
      debugPrint('📍 savePlace: Checking for photo to upload...');
      if (selectedImagePath.value != null || selectedImageBytes.value != null) {
        debugPrint('📍 savePlace: Photo found, uploading...');
        photoUrl = await _uploadPhoto();
        debugPrint('📍 savePlace: Photo URL after upload: $photoUrl');
      } else {
        debugPrint('📍 savePlace: No photo selected');
      }

      final place = MemorableModel(
        id: '', // Will be set by Firestore
        name: nameController.text.trim(),
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        latitude: latitude.value!,
        longitude: longitude.value!,
        accuracy: accuracy.value,
        category: selectedCategory.value,
        photoUrl: photoUrl,
        createdAt: DateTime.now(),
        createdBy: currentUserId!,
      );

      await _firestore.collection('memorable_places').add(place.toFirestore());

      Get.snackbar(
        'Berhasil Disimpan! 🎉',
        '${place.name} telah ditambahkan ke daftar tempat memorable',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Reset form
      _resetForm();

      // Reload places
      await loadPlaces();
    } catch (e) {
      debugPrint('Error saving place: $e');
      Get.snackbar(
        'Gagal Menyimpan',
        'Terjadi kesalahan. Mohon coba lagi.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    }

    isSaving.value = false;
  }

  /// Delete a place
  Future<void> deletePlace(MemorableModel place) async {
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
      await _firestore.collection('memorable_places').doc(place.id).delete();

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

  /// Update an existing place
  Future<void> updatePlace(
    MemorableModel updatedPlace, {
    String? newImagePath,
  }) async {
    try {
      String? photoUrl = updatedPlace.photoUrl;

      // Upload new photo if provided
      if (newImagePath != null) {
        debugPrint('📍 updatePlace: Uploading new photo...');

        // Delete old photo if exists
        if (updatedPlace.photoUrl != null) {
          try {
            await _storage.refFromURL(updatedPlace.photoUrl!).delete();
          } catch (e) {
            debugPrint('Error deleting old photo: $e');
          }
        }

        // Upload new photo
        final fileName =
            'memorable_${currentUserId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = _storage.ref().child('memorable_photos/$fileName');

        if (kIsWeb) {
          // For web, read file as bytes
          final file = await XFile(newImagePath).readAsBytes();
          final uploadTask = await ref.putData(
            file,
            SettableMetadata(contentType: 'image/jpeg'),
          );
          photoUrl = await uploadTask.ref.getDownloadURL();
        } else {
          final file = File(newImagePath);
          final uploadTask = await ref.putFile(file);
          photoUrl = await uploadTask.ref.getDownloadURL();
        }

        debugPrint('📍 updatePlace: New photo uploaded: $photoUrl');
      }

      // Update in Firestore
      await _firestore
          .collection('memorable_places')
          .doc(updatedPlace.id)
          .update({
            'name': updatedPlace.name,
            'description': updatedPlace.description,
            'category': updatedPlace.category.name,
            'photoUrl': photoUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Update local list
      final index = places.indexWhere((p) => p.id == updatedPlace.id);
      if (index != -1) {
        places[index] = updatedPlace.copyWith(photoUrl: photoUrl);
      }

      debugPrint('📍 updatePlace: Place updated successfully');
    } catch (e) {
      debugPrint('Error updating place: $e');
      rethrow;
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
  }

  /// Open location in Google Maps (shows coordinates for now)
  void openInMaps(MemorableModel place) {
    // TODO: Add url_launcher package to open in Google Maps
    Get.snackbar(
      'Koordinat',
      place.formattedCoordinates,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 5),
    );
  }

  /// Open current form location in Google Maps
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

  /// Focus map on specific location
  void focusOnLocation(double lat, double lng) {
    final position = LatLng(lat, lng);

    // Update marker and state
    latitude.value = lat;
    longitude.value = lng;

    marker.value = Marker(
      markerId: const MarkerId('selected_location'),
      position: position,
      draggable: true,
      onDragEnd: _onMarkerDragEnd,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: const InfoWindow(title: 'Lokasi Terpilih'),
    );

    // Animate camera
    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(position, defaultZoomLevel),
    );
  }
}
