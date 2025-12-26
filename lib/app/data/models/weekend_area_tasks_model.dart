import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for weekend area tasks configuration
class WeekendAreaTasksModel {
  final String
  area; // 'Halaman', 'Kamar Aula', 'Tempat Wudhu', 'Rongsokan', 'Masjid', 'Dapur', 'Masak'
  final List<String> tasks;
  final DateTime? updatedAt;

  WeekendAreaTasksModel({
    required this.area,
    required this.tasks,
    this.updatedAt,
  });

  factory WeekendAreaTasksModel.fromJson(Map<String, dynamic> json) {
    return WeekendAreaTasksModel(
      area: json['area'] as String,
      tasks: List<String>.from(json['tasks'] as List),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'area': area,
      'tasks': tasks,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  WeekendAreaTasksModel copyWith({
    String? area,
    List<String>? tasks,
    DateTime? updatedAt,
  }) {
    return WeekendAreaTasksModel(
      area: area ?? this.area,
      tasks: tasks ?? this.tasks,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Default tasks for each weekend area
  static const Map<String, List<String>> defaultTasks = {
    'Halaman': [
      'Sapu Halaman Depan',
      'Sapu Halaman Belakang',
      'Bersihkan Sampah',
      'Siram Tanaman',
      'Rapikan Barang',
    ],
    'Kamar Aula': [
      'Sapu Lantai Aula',
      'Pel Lantai Aula',
      'Rapikan Kursi & Meja',
      'Bersihkan Jendela',
      'Bersihkan Kipas/AC',
    ],
    'Tempat Wudhu': [
      'Bersihkan Lantai Tempat Wudhu',
      'Sikat Dinding',
      'Bersihkan Kran',
      'Rapikan Sandal',
      'Isi Air',
    ],
    'Rongsokan': [
      'Sortir Barang Bekas',
      'Bersihkan Area Rongsokan',
      'Rapikan Tumpukan',
      'Buang Sampah',
      'Timbang Barang (jika perlu)',
    ],
    'Masjid': [
      'Sapu Lantai Masjid',
      'Pel Lantai Masjid',
      'Rapikan Karpet Sholat',
      'Bersihkan Mimbar',
      'Rapikan Rak Al-Quran',
    ],
    'Dapur': [
      'Cuci Semua Piring & Peralatan',
      'Bersihkan Kompor',
      'Bersihkan Meja Masak',
      'Pel Lantai Dapur',
      'Rapikan Peralatan Masak',
      'Buang Sampah Dapur',
    ],
    'Masak': [
      'Siapkan Bahan Masakan',
      'Masak Nasi',
      'Masak Lauk Utama',
      'Masak Sayur',
      'Siapkan Sambal/Pelengkap',
      'Cuci Peralatan Masak',
      'Rapikan Dapur Setelah Masak',
    ],
  };

  /// Get default tasks for an area
  static List<String> getDefaultTasksForArea(String area) {
    return defaultTasks[area] ?? [];
  }
}
