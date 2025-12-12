class DailyIbadahModel {
  final String id; // Format: {userId}-{date}
  final String userId;
  final String date; // Format: yyyy-MM-dd

  // Sholat Wajib
  final bool? subuhQobliyah;
  final bool? subuhJamaah;
  final bool? dzuhurJamaah;
  final bool? dzuhurBadiyah;
  final bool? asharJamaah;
  final bool? maghribJamaah;
  final bool? maghribBadiyah;
  final bool? isyaJamaah;
  final bool? isyaBadiyah;

  // Amalan Harian (yang sudah ada)
  final bool? sholatDhuha;
  final bool? alMulk;

  // Amalan Harian baru
  final bool? tahajud;
  final bool? surah56; // Al-Waqi'ah
  final bool? alkahfiOrYasin; // Jumat: Al-Kahfi (18), Hari Lain: Yasin (36)

  // Fisik
  final int? pushup;
  final String? notes;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DailyIbadahModel({
    required this.id,
    required this.userId,
    required this.date,
    // Sholat Wajib
    this.subuhQobliyah,
    this.subuhJamaah,
    this.dzuhurJamaah,
    this.dzuhurBadiyah,
    this.asharJamaah,
    this.maghribJamaah,
    this.maghribBadiyah,
    this.isyaJamaah,
    this.isyaBadiyah,
    // Amalan Harian
    this.sholatDhuha,
    this.alMulk,
    this.tahajud,
    this.surah56,
    this.alkahfiOrYasin,
    // Fisik
    this.pushup,
    this.notes,
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
      // Sholat Wajib
      subuhQobliyah: map['subuh_qobliyah'] as bool?,
      subuhJamaah: map['subuh_jamaah'] as bool?,
      dzuhurJamaah: map['dzuhur_jamaah'] as bool?,
      dzuhurBadiyah: map['dzuhur_badiyah'] as bool?,
      asharJamaah: map['ashar_jamaah'] as bool?,
      maghribJamaah: map['maghrib_jamaah'] as bool?,
      maghribBadiyah: map['maghrib_badiyah'] as bool?,
      isyaJamaah: map['isya_jamaah'] as bool?,
      isyaBadiyah: map['isya_badiyah'] as bool?,
      // Amalan Harian
      sholatDhuha: map['sholat_dhuha'] as bool?,
      alMulk: map['al_mulk'] as bool?,
      tahajud: map['tahajud'] as bool?,
      surah56: map['surah56'] as bool?,
      alkahfiOrYasin: map['alkahfi_or_yasin'] as bool?,
      // Fisik
      pushup: map['pushup'] as int?,
      notes: map['notes'] as String?,
      createdAt: map['created_at']?.toDate(),
      updatedAt: map['updated_at']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'date': date,
      // Sholat Wajib
      if (subuhQobliyah != null) 'subuh_qobliyah': subuhQobliyah,
      if (subuhJamaah != null) 'subuh_jamaah': subuhJamaah,
      if (dzuhurJamaah != null) 'dzuhur_jamaah': dzuhurJamaah,
      if (dzuhurBadiyah != null) 'dzuhur_badiyah': dzuhurBadiyah,
      if (asharJamaah != null) 'ashar_jamaah': asharJamaah,
      if (maghribJamaah != null) 'maghrib_jamaah': maghribJamaah,
      if (maghribBadiyah != null) 'maghrib_badiyah': maghribBadiyah,
      if (isyaJamaah != null) 'isya_jamaah': isyaJamaah,
      if (isyaBadiyah != null) 'isya_badiyah': isyaBadiyah,
      // Amalan Harian
      if (sholatDhuha != null) 'sholat_dhuha': sholatDhuha,
      if (alMulk != null) 'al_mulk': alMulk,
      if (tahajud != null) 'tahajud': tahajud,
      if (surah56 != null) 'surah56': surah56,
      if (alkahfiOrYasin != null) 'alkahfi_or_yasin': alkahfiOrYasin,
      // Fisik
      if (pushup != null) 'pushup': pushup,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  // Computed properties
  int get totalItems => 15; // 9 sholat wajib + 5 amalan + 1 pushup >= 25

  int get completedItems {
    int count = 0;
    // Sholat Wajib (9 items)
    if (subuhQobliyah == true) count++;
    if (subuhJamaah == true) count++;
    if (dzuhurJamaah == true) count++;
    if (dzuhurBadiyah == true) count++;
    if (asharJamaah == true) count++;
    if (maghribJamaah == true) count++;
    if (maghribBadiyah == true) count++;
    if (isyaJamaah == true) count++;
    if (isyaBadiyah == true) count++;
    // Amalan Harian (5 items)
    if (tahajud == true) count++;
    if (sholatDhuha == true) count++;
    if (alMulk == true) count++;
    if (surah56 == true) count++;
    if (alkahfiOrYasin == true) count++;
    // Fisik (1 item - pushup >= 25)
    if (pushup != null && pushup! >= 25) count++;
    return count;
  }

  double calculateLevelPercentage() {
    if (totalItems == 0) return 0;
    return completedItems / totalItems;
  }

  DailyIbadahModel copyWith({
    String? id,
    String? userId,
    String? date,
    // Sholat Wajib
    bool? subuhQobliyah,
    bool? subuhJamaah,
    bool? dzuhurJamaah,
    bool? dzuhurBadiyah,
    bool? asharJamaah,
    bool? maghribJamaah,
    bool? maghribBadiyah,
    bool? isyaJamaah,
    bool? isyaBadiyah,
    // Amalan Harian
    bool? sholatDhuha,
    bool? alMulk,
    bool? tahajud,
    bool? surah56,
    bool? alkahfiOrYasin,
    // Fisik
    int? pushup,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyIbadahModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      // Sholat Wajib
      subuhQobliyah: subuhQobliyah ?? this.subuhQobliyah,
      subuhJamaah: subuhJamaah ?? this.subuhJamaah,
      dzuhurJamaah: dzuhurJamaah ?? this.dzuhurJamaah,
      dzuhurBadiyah: dzuhurBadiyah ?? this.dzuhurBadiyah,
      asharJamaah: asharJamaah ?? this.asharJamaah,
      maghribJamaah: maghribJamaah ?? this.maghribJamaah,
      maghribBadiyah: maghribBadiyah ?? this.maghribBadiyah,
      isyaJamaah: isyaJamaah ?? this.isyaJamaah,
      isyaBadiyah: isyaBadiyah ?? this.isyaBadiyah,
      // Amalan Harian
      sholatDhuha: sholatDhuha ?? this.sholatDhuha,
      alMulk: alMulk ?? this.alMulk,
      tahajud: tahajud ?? this.tahajud,
      surah56: surah56 ?? this.surah56,
      alkahfiOrYasin: alkahfiOrYasin ?? this.alkahfiOrYasin,
      // Fisik
      pushup: pushup ?? this.pushup,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
