import 'package:cloud_firestore/cloud_firestore.dart';

import 'weekend_task_item.dart';

/// Model for weekend area tasks configuration
class WeekendAreaTasksModel {
  final String
  area; // 'Halaman', 'Kamar Aula', 'Tempat Wudhu', 'Rongsokan', 'Masjid', 'Dapur', 'Masak'
  final List<WeekendTaskItem> tasks;
  final DateTime? updatedAt;

  WeekendAreaTasksModel({
    required this.area,
    required this.tasks,
    this.updatedAt,
  });

  factory WeekendAreaTasksModel.fromJson(Map<String, dynamic> json) {
    final rawTasks = json['tasks'] as List?;
    List<WeekendTaskItem> parsedTasks = [];

    if (rawTasks != null) {
      for (final item in rawTasks) {
        if (item is String) {
          // Legacy format: convert string to WeekendTaskItem
          parsedTasks.add(WeekendTaskItem.fromString(item));
        } else if (item is Map<String, dynamic>) {
          // New format: parse as WeekendTaskItem
          parsedTasks.add(WeekendTaskItem.fromJson(item));
        }
      }
    }

    return WeekendAreaTasksModel(
      area: json['area'] as String,
      tasks: parsedTasks,
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'area': area,
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  WeekendAreaTasksModel copyWith({
    String? area,
    List<WeekendTaskItem>? tasks,
    DateTime? updatedAt,
  }) {
    return WeekendAreaTasksModel(
      area: area ?? this.area,
      tasks: tasks ?? this.tasks,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get tasks filtered by day (sabtu/ahad)
  List<WeekendTaskItem> getTasksForDay(String day) {
    return tasks.where((t) => t.isVisibleOnDay(day)).toList();
  }

  /// Get task names only (for backward compatibility)
  List<String> get taskNames => tasks.map((t) => t.name).toList();

  /// Default tasks for each weekend area
  static const Map<String, List<Map<String, String>>> defaultTasks = {
    'Halaman': [
      {'name': 'Sapu Halaman Depan', 'dayOption': 'both'},
      {'name': 'Sapu Halaman Belakang', 'dayOption': 'both'},
      {'name': 'Bersihkan Sampah', 'dayOption': 'both'},
      {'name': 'Siram Tanaman', 'dayOption': 'sabtu'},
      {'name': 'Rapikan Barang', 'dayOption': 'ahad'},
    ],
    'Kamar Aula': [
      {'name': 'Sapu Lantai Aula', 'dayOption': 'both'},
      {'name': 'Pel Lantai Aula', 'dayOption': 'both'},
      {'name': 'Rapikan Kursi & Meja', 'dayOption': 'both'},
      {'name': 'Bersihkan Jendela', 'dayOption': 'sabtu'},
      {'name': 'Bersihkan Kipas/AC', 'dayOption': 'ahad'},
    ],
    'Tempat Wudhu': [
      {'name': 'Bersihkan Lantai Tempat Wudhu', 'dayOption': 'both'},
      {'name': 'Sikat Dinding', 'dayOption': 'both'},
      {'name': 'Bersihkan Kran', 'dayOption': 'both'},
      {'name': 'Rapikan Sandal', 'dayOption': 'both'},
      {'name': 'Isi Air', 'dayOption': 'both'},
    ],
    'Rongsokan': [
      {'name': 'Sortir Barang Bekas', 'dayOption': 'both'},
      {'name': 'Bersihkan Area Rongsokan', 'dayOption': 'both'},
      {'name': 'Rapikan Tumpukan', 'dayOption': 'both'},
      {'name': 'Buang Sampah', 'dayOption': 'both'},
      {'name': 'Timbang Barang (jika perlu)', 'dayOption': 'ahad'},
    ],
    'Masjid': [
      {'name': 'Sapu Lantai Masjid', 'dayOption': 'both'},
      {'name': 'Pel Lantai Masjid', 'dayOption': 'both'},
      {'name': 'Rapikan Karpet Sholat', 'dayOption': 'both'},
      {'name': 'Bersihkan Mimbar', 'dayOption': 'sabtu'},
      {'name': 'Rapikan Rak Al-Quran', 'dayOption': 'ahad'},
    ],
    'Dapur': [
      {'name': 'Cuci Semua Piring & Peralatan', 'dayOption': 'both'},
      {'name': 'Bersihkan Kompor', 'dayOption': 'both'},
      {'name': 'Bersihkan Meja Masak', 'dayOption': 'both'},
      {'name': 'Pel Lantai Dapur', 'dayOption': 'both'},
      {'name': 'Rapikan Peralatan Masak', 'dayOption': 'both'},
      {'name': 'Buang Sampah Dapur', 'dayOption': 'both'},
    ],
    'Masak': [
      {'name': 'Siapkan Bahan Masakan', 'dayOption': 'both'},
      {'name': 'Masak Nasi', 'dayOption': 'both'},
      {'name': 'Masak Lauk Utama', 'dayOption': 'both'},
      {'name': 'Masak Sayur', 'dayOption': 'both'},
      {'name': 'Siapkan Sambal/Pelengkap', 'dayOption': 'both'},
      {'name': 'Cuci Peralatan Masak', 'dayOption': 'both'},
      {'name': 'Rapikan Dapur Setelah Masak', 'dayOption': 'both'},
    ],
  };

  /// Get default tasks for an area as WeekendTaskItem list
  static List<WeekendTaskItem> getDefaultTasksForArea(String area) {
    final defaults = defaultTasks[area];
    if (defaults == null) return [];
    return defaults
        .map(
          (t) => WeekendTaskItem(
            name: t['name']!,
            dayOption: t['dayOption'] ?? 'both',
          ),
        )
        .toList();
  }

  /// Get default task names for an area (legacy compatibility)
  static List<String> getDefaultTaskNamesForArea(String area) {
    return getDefaultTasksForArea(area).map((t) => t.name).toList();
  }
}
