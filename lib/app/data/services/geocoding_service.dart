import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

/// Service for converting coordinates to addresses (reverse geocoding)
class GeocodingService {
  static final GeocodingService _instance = GeocodingService._internal();
  factory GeocodingService() => _instance;
  GeocodingService._internal();

  /// Google Maps API Key (same as used in web/index.html)
  static const String _googleMapsApiKey =
      'AIzaSyAdNC8ZxXPzjJnFwZ3kpeYXN72yIN1B1f8';

  /// Cache for addresses to avoid repeated API calls
  final Map<String, String> _addressCache = {};

  /// Convert coordinates to a formatted Indonesian address
  /// Returns address in format: Desa/Kelurahan, Kecamatan, Kabupaten/Kota
  Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude, {
    bool shortFormat = true,
  }) async {
    final cacheKey =
        '${latitude.toStringAsFixed(6)}_${longitude.toStringAsFixed(6)}';

    // Check cache first
    if (_addressCache.containsKey(cacheKey)) {
      return _addressCache[cacheKey]!;
    }

    try {
      String address;

      if (kIsWeb) {
        // Use Google Maps Geocoding API for web
        address = await _getAddressFromGoogleApi(
          latitude,
          longitude,
          shortFormat,
        );
      } else {
        // Use native geocoding for mobile
        address = await _getAddressFromNativeGeocoding(
          latitude,
          longitude,
          shortFormat,
        );
      }

      // Cache the result
      _addressCache[cacheKey] = address;
      return address;
    } catch (e) {
      debugPrint('Error getting address: $e');
      return 'Gagal mendapatkan alamat';
    }
  }

  /// Get address using Google Maps Geocoding API (for web)
  Future<String> _getAddressFromGoogleApi(
    double latitude,
    double longitude,
    bool shortFormat,
  ) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=$latitude,$longitude'
        '&key=$_googleMapsApiKey'
        '&language=id',
      );

      debugPrint('Geocoding request: $url');
      final response = await http.get(url);
      debugPrint('Geocoding response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status = data['status'] as String?;
        debugPrint('Geocoding API status: $status');

        if (status == 'OK') {
          final results = data['results'] as List<dynamic>?;
          if (results != null && results.isNotEmpty) {
            return _parseGoogleGeocodingResult(results, shortFormat);
          }
        } else if (status == 'REQUEST_DENIED') {
          debugPrint('Geocoding API error: ${data['error_message']}');
          return 'API tidak tersedia';
        }
      }

      return 'Alamat tidak ditemukan';
    } catch (e, stackTrace) {
      debugPrint('Geocoding API error: $e');
      debugPrint('Stack trace: $stackTrace');
      return 'Gagal memuat alamat';
    }
  }

  /// Parse Google Geocoding API response
  String _parseGoogleGeocodingResult(List<dynamic> results, bool shortFormat) {
    String? desa; // administrative_area_level_4 or sublocality
    String? kecamatan; // administrative_area_level_3 or locality
    String? kabupaten; // administrative_area_level_2

    // Iterate through all results to find the best components
    for (final result in results) {
      if (result == null) continue;

      final components = result['address_components'] as List<dynamic>?;
      if (components == null) continue;

      for (final component in components) {
        if (component == null) continue;

        final typesRaw = component['types'] as List<dynamic>?;
        if (typesRaw == null) continue;

        final types = typesRaw.whereType<String>().toList();
        final name = component['long_name'] as String?;
        if (name == null || name.isEmpty) continue;

        // Desa/Kelurahan
        if (desa == null &&
            (types.contains('administrative_area_level_4') ||
                types.contains('sublocality') ||
                types.contains('sublocality_level_1'))) {
          desa = name;
        }

        // Kecamatan
        if (kecamatan == null &&
            (types.contains('administrative_area_level_3') ||
                types.contains('locality'))) {
          kecamatan = name;
        }

        // Kabupaten/Kota
        if (kabupaten == null &&
            types.contains('administrative_area_level_2')) {
          kabupaten = name;
        }
      }
    }

    final parts = <String>[];

    if (desa != null && desa.isNotEmpty) {
      parts.add(desa);
    }
    if (kecamatan != null && kecamatan.isNotEmpty) {
      parts.add(kecamatan);
    }
    if (!shortFormat && kabupaten != null && kabupaten.isNotEmpty) {
      parts.add(kabupaten);
    }

    return parts.isEmpty ? 'Lokasi tidak diketahui' : parts.join(', ');
  }

  /// Get address using native geocoding (for mobile)
  Future<String> _getAddressFromNativeGeocoding(
    double latitude,
    double longitude,
    bool shortFormat,
  ) async {
    final placemarks = await placemarkFromCoordinates(latitude, longitude);

    if (placemarks.isNotEmpty) {
      final place = placemarks.first;

      if (shortFormat) {
        return _formatShortAddress(place);
      } else {
        return _formatFullAddress(place);
      }
    }

    return 'Alamat tidak ditemukan';
  }

  /// Format short address (Desa/Kelurahan, Kecamatan)
  String _formatShortAddress(Placemark place) {
    final parts = <String>[];

    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      parts.add(place.subLocality!);
    }

    if (place.locality != null && place.locality!.isNotEmpty) {
      parts.add(place.locality!);
    }

    if (parts.isEmpty) {
      if (place.subAdministrativeArea != null &&
          place.subAdministrativeArea!.isNotEmpty) {
        parts.add(place.subAdministrativeArea!);
      }
    }

    return parts.isEmpty ? 'Lokasi tidak diketahui' : parts.join(', ');
  }

  /// Format full address (Desa, Kecamatan, Kabupaten)
  String _formatFullAddress(Placemark place) {
    final parts = <String>[];

    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      parts.add(place.subLocality!);
    }

    if (place.locality != null && place.locality!.isNotEmpty) {
      parts.add(place.locality!);
    }

    if (place.subAdministrativeArea != null &&
        place.subAdministrativeArea!.isNotEmpty) {
      parts.add(place.subAdministrativeArea!);
    }

    return parts.isEmpty ? 'Lokasi tidak diketahui' : parts.join(', ');
  }

  /// Clear address cache
  void clearCache() {
    _addressCache.clear();
  }
}
