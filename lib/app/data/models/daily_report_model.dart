import 'task_model.dart';

class DailyReportModel {
  final String id;
  final String date;
  final int kelompokId;
  final String areaTugas;
  final String status; // pending | verified | rejected
  final List<TaskModel> tasks;
  final int? finalScore; // Total poin harian (jumlah task valid * 5)
  final String? photoUrl; // URL foto bukti

  const DailyReportModel({
    required this.id,
    required this.date,
    required this.kelompokId,
    required this.areaTugas,
    required this.status,
    required this.tasks,
    this.finalScore,
    this.photoUrl,
  });

  factory DailyReportModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    final taskList = (map['tasks'] as List<dynamic>? ?? [])
        .map((e) => TaskModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    return DailyReportModel(
      id: documentId,
      date: map['date'] ?? '',
      kelompokId: map['kelompok_id'] ?? 0,
      areaTugas: map['area_tugas'] ?? '',
      status: map['status'] ?? 'pending',
      tasks: taskList,
      finalScore: map['final_score'],
      photoUrl: map['photo_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'kelompok_id': kelompokId,
      'area_tugas': areaTugas,
      'status': status,
      'tasks': tasks.map((e) => e.toMap()).toList(),
      if (finalScore != null) 'final_score': finalScore,
      if (photoUrl != null) 'photo_url': photoUrl,
    };
  }
}
