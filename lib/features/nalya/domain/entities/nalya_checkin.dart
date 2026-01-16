/// Nalya Check-in Entity
/// Pure Dart class for Nalya location check-in

class NalyaCheckIn {
  final String id;
  final String userId;
  final String userName;
  final DateTime checkInTime;
  final double latitude;
  final double longitude;
  final String locationName;
  final bool isValid; // Within Nalya area
  final String? notes;

  const NalyaCheckIn({
    required this.id,
    required this.userId,
    required this.userName,
    required this.checkInTime,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.isValid,
    this.notes,
  });

  NalyaCheckIn copyWith({
    String? id,
    String? userId,
    String? userName,
    DateTime? checkInTime,
    double? latitude,
    double? longitude,
    String? locationName,
    bool? isValid,
    String? notes,
  }) {
    return NalyaCheckIn(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      checkInTime: checkInTime ?? this.checkInTime,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      isValid: isValid ?? this.isValid,
      notes: notes ?? this.notes,
    );
  }
}
