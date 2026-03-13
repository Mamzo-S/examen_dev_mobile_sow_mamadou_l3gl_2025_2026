enum TaskStatus { todo, inProgress, done }

enum TaskPriority { high, medium, low }

class Task {
  final String id;
  final String projectId;
  final String userId;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? dueDate;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.title,
    this.description,
    this.status = TaskStatus.todo,
    this.priority = TaskPriority.medium,
    this.dueDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'userId': userId,
      'title': title,
      'description': description ?? '',
      'status': status.name,
      'priority': priority.name,
      'dueDate': dueDate?.toIso8601String() ?? '',
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    final statusRaw = (map['status'] ?? 'todo').toString();

    TaskStatus parsedStatus = TaskStatus.todo;
    for (final s in TaskStatus.values) {
      if (s.name == statusRaw) parsedStatus = s;
    }

    final priorityRaw = (map['priority'] ?? TaskPriority.medium.name).toString();
    TaskPriority parsedPriority = TaskPriority.medium;
    for (final p in TaskPriority.values) {
      if (p.name == priorityRaw) parsedPriority = p;
    }

    final dueRaw = (map['dueDate'] ?? '').toString();
    final due = dueRaw.isEmpty ? null : DateTime.tryParse(dueRaw);

    return Task(
      id: (map['id'] ?? '').toString(),
      projectId: (map['projectId'] ?? '').toString(),
      userId: (map['userId'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      status: parsedStatus,
      priority: parsedPriority,
      dueDate: due,
      createdAt: DateTime.tryParse((map['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}
