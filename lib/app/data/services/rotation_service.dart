import 'package:intl/intl.dart';

import 'firestore_service.dart';
import 'weekend_rotation_service.dart';

class RotationService {
  RotationService({FirestoreService? firestore})
    : _firestore = firestore ?? FirestoreService.instance;

  final FirestoreService _firestore;
  final _weekendRotation = WeekendRotationService.instance;

  /// Base order for Monday: [Kamar, Parkiran, Masjid, Masak, Halaman]
  static const List<String> _baseAreas = [
    'Kamar',
    'Parkiran',
    'Masjid',
    'Masak',
    'Halaman',
  ];

  /// Returns area for given kelompokId (1-5) and date.
  String getAreaForGroup(int kelompokId, DateTime date) {
    final weekday = date.weekday; // 1=Mon, ... 7=Sun
    // Weekend: get actual piket area from weekend schedule
    if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
      final slotInfo = _weekendRotation.getSlotForKelompok(kelompokId, date);
      if (slotInfo != null) {
        // Return area based on day
        if (weekday == DateTime.saturday) {
          return slotInfo.piketAreaSabtu;
        } else {
          return slotInfo.piketAreaAhad;
        }
      }
      return 'Piket Weekend'; // Fallback
    }
    final offset = weekday - DateTime.monday;
    final index = (kelompokId - 1 + offset) % _baseAreas.length;
    return _baseAreas[index];
  }

  Future<List<String>> getTasksForArea(String area) async {
    final data = await _firestore.getAreaTasks(area);
    if (data != null && data.tasks.isNotEmpty) {
      return data.tasks;
    }
    // fallback defaults
    return _defaultTasks[area] ?? [];
  }

  String todayId(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  Map<String, List<String>> get defaultTasks => _defaultTasks;
  List<String> get areas => List.unmodifiable(_baseAreas);

  static const Map<String, List<String>> _defaultTasks = {
    'Kamar': [
      'Sapu Lantai',
      'Pel Lantai',
      'Bersihkan Tempat Tidur',
      'Rapikan Lemari',
      'Bersihkan Jendela',
    ],
    'Parkiran': [
      'Sapu Area Parkir',
      'Bersihkan Sampah',
      'Rapikan Sepeda',
      'Bersihkan Debu Kendaraan',
      'Rapikan Barang',
    ],
    'Masjid': [
      'Sapu Lantai Masjid',
      'Pel Lantai Masjid',
      'Bersihkan Karpet',
      'Rapikan Sandal',
      'Bersihkan Tempat Wudhu',
    ],
    'Masak': [
      'Cuci Piring',
      'Bersihkan Meja Makan',
      'Sapu Dapur',
      'Pel Dapur',
      'Rapikan Peralatan Masak',
    ],
    'Halaman': [
      'Sapu Halaman',
      'Bersihkan Sampah',
      'Siram Tanaman',
      'Rapikan Barang',
      'Bersihkan Selokan',
    ],
  };

  Future<void> seedDefaults() async {
    await _firestore.ensureDefaultAreaTasks(_defaultTasks);
  }
}
