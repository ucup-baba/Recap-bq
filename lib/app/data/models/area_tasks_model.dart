class AreaTasksModel {
  final String area;
  final List<String> tasks;

  const AreaTasksModel({required this.area, required this.tasks});

  factory AreaTasksModel.fromMap(Map<String, dynamic> map) {
    return AreaTasksModel(
      area: map['area'] ?? '',
      tasks: List<String>.from(map['tasks'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {'area': area, 'tasks': tasks};
  }
}
