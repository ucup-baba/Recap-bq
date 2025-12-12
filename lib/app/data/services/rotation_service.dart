import 'package:intl/intl.dart';

import 'firestore_service.dart';

class RotationService {
  RotationService({FirestoreService? firestore})
    : _firestore = firestore ?? FirestoreService.instance;

  final FirestoreService _firestore;

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
    if (weekday < DateTime.monday || weekday > DateTime.friday) {
      return 'Libur';
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
