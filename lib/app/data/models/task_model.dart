class TaskModel {
  final String taskName;
  final bool isDone;
  final List<String> executors;
  final bool? isValid;
  final String? adminNote;

  const TaskModel({
    required this.taskName,
    required this.isDone,
    required this.executors,
    this.isValid,
    this.adminNote,
  });

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      taskName: map['task_name'] ?? '',
      isDone: map['is_done'] ?? false,
      executors: List<String>.from(map['executors'] ?? []),
      isValid: map['is_valid'],
      adminNote: map['admin_note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'task_name': taskName,
      'is_done': isDone,
      'executors': executors,
      'is_valid': isValid,
      'admin_note': adminNote,
    };
  }

  TaskModel copyWith({
    String? taskName,
    bool? isDone,
    List<String>? executors,
    bool? isValid,
    String? adminNote,
  }) {
    return TaskModel(
      taskName: taskName ?? this.taskName,
      isDone: isDone ?? this.isDone,
      executors: executors ?? this.executors,
      isValid: isValid ?? this.isValid,
      adminNote: adminNote ?? this.adminNote,
    );
  }
}
