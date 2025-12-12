class KelompokMembersModel {
  final int kelompokId;
  final List<String> members;

  const KelompokMembersModel({required this.kelompokId, required this.members});

  factory KelompokMembersModel.fromMap(Map<String, dynamic> map) {
    return KelompokMembersModel(
      kelompokId: map['kelompok_id'] ?? 0,
      members: List<String>.from(map['members'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {'kelompok_id': kelompokId, 'members': members};
  }
}
