class DailyIbadahModel {
  final String id; // Format: {userId}-{date}
  final String userId;
  final String date; // Format: yyyy-MM-dd
  final bool? sholatDhuha;
  final bool? alMulk;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DailyIbadahModel({
    required this.id,
    required this.userId,
    required this.date,
    this.sholatDhuha,
    this.alMulk,
    this.createdAt,
    this.updatedAt,
  });

  factory DailyIbadahModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return DailyIbadahModel(
      id: documentId,
      userId: map['user_id'] ?? '',
      date: map['date'] ?? '',
      sholatDhuha: map['sholat_dhuha'] as bool?,
      alMulk: map['al_mulk'] as bool?,
      createdAt: map['created_at']?.toDate(),
      updatedAt: map['updated_at']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'date': date,
      if (sholatDhuha != null) 'sholat_dhuha': sholatDhuha,
      if (alMulk != null) 'al_mulk': alMulk,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  DailyIbadahModel copyWith({
    String? id,
    String? userId,
    String? date,
    bool? sholatDhuha,
    bool? alMulk,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyIbadahModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      sholatDhuha: sholatDhuha ?? this.sholatDhuha,
      alMulk: alMulk ?? this.alMulk,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
