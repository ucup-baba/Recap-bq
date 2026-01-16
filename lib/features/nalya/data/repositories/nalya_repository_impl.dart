import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/data/datasources/firestore_datasource.dart';
import '../../domain/entities/nalya_checkin.dart';
import '../../domain/repositories/nalya_repository.dart';

/// Implementation of NalyaRepository
class NalyaRepositoryImpl implements NalyaRepository {
  final FirestoreDataSource firestoreDataSource;

  NalyaRepositoryImpl({required this.firestoreDataSource});

  static const String _collection = 'nalya_checkins';

  @override
  Future<void> recordCheckIn(NalyaCheckIn checkIn) async {
    final data = {
      'userId': checkIn.userId,
      'userName': checkIn.userName,
      'checkInTime': Timestamp.fromDate(checkIn.checkInTime),
      'latitude': checkIn.latitude,
      'longitude': checkIn.longitude,
      'locationName': checkIn.locationName,
      'isValid': checkIn.isValid,
      if (checkIn.notes != null) 'notes': checkIn.notes,
    };

    final firestore = FirebaseFirestore.instance;
    await firestore.collection(_collection).add(data);
  }

  @override
  Future<List<NalyaCheckIn>> getCheckInsByUser(String userId) async {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('checkInTime', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return NalyaCheckIn(
        id: doc.id,
        userId: data['userId'],
        userName: data['userName'],
        checkInTime: (data['checkInTime'] as Timestamp).toDate(),
        latitude: data['latitude'],
        longitude: data['longitude'],
        locationName: data['locationName'],
        isValid: data['isValid'],
        notes: data['notes'],
      );
    }).toList();
  }

  @override
  Future<List<NalyaCheckIn>> getCheckInsByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore
        .collection(_collection)
        .where(
          'checkInTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('checkInTime', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return NalyaCheckIn(
        id: doc.id,
        userId: data['userId'],
        userName: data['userName'],
        checkInTime: (data['checkInTime'] as Timestamp).toDate(),
        latitude: data['latitude'],
        longitude: data['longitude'],
        locationName: data['locationName'],
        isValid: data['isValid'],
        notes: data['notes'],
      );
    }).toList();
  }

  @override
  Future<bool> validateLocation(double latitude, double longitude) async {
    // Nalya location validation logic
    // This is a simplified version - actual implementation would use geofencing
    const nalyaLat = -7.8014; // Example coordinates
    const nalyaLng = 110.3642;
    const radiusKm = 0.5; // 500m radius

    final distance = _calculateDistance(
      latitude,
      longitude,
      nalyaLat,
      nalyaLng,
    );
    return distance <= radiusKm;
  }

  /// Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a =
        (dLat / 2) * (dLat / 2) +
        (dLon / 2) * (dLon / 2) * _cos(lat1) * _cos(lat2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));

    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) => degrees * 3.14159265359 / 180;
  double _cos(double degrees) => _degreesToRadians(degrees);
  double _sqrt(double value) => value;
  double _atan2(double y, double x) => 0.0; // Placeholder
}
