import 'package:flutter/material.dart';
import 'package:sunu_task/models/task.dart';
import 'package:sunu_task/services/storage_service.dart';
import 'package:uuid/uuid.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  TaskStatus? _statusFilter;
  TaskPriority? _priorityFilter;
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  TaskStatus? get statusFilter => _statusFilter;
  TaskPriority? get priorityFilter => _priorityFilter;

  // Taches filtrees + triees pour l'UI.
  List<Task> get tasks {
    Iterable<Task> result = _tasks;
    if (_statusFilter != null) {
      result = result.where((t) => t.status == _statusFilter);
    }
    if (_priorityFilter != null) {
      result = result.where((t) => t.priority == _priorityFilter);
    }

    final list = result.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Map<TaskStatus, int> get taskCountByStatus {
    final counts = <TaskStatus, int>{
      TaskStatus.todo: 0,
      TaskStatus.inProgress: 0,
      TaskStatus.done: 0,
    };
    for (final t in _tasks) {
      counts[t.status] = (counts[t.status] ?? 0) + 1;
    }
    return counts;
  }

  int get taskCount => _tasks.length;

  Map<String, int> get taskCountByProjectId {
    final counts = <String, int>{};
    for (final t in _tasks) {
      counts[t.projectId] = (counts[t.projectId] ?? 0) + 1;
    }
    return counts;
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  Future<void> loadUserTasks(String userId) async {
    _setLoading(true);
    try {
      _tasks = await StorageService.instance.getTasksByUserId(userId);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadTasks(String projectId) async {
    _setLoading(true);
    try {
      _tasks = await StorageService.instance.getTasksByProjectId(projectId);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createTask({
    required String userId,
    required String projectId,
    required String title,
    String? description,
    TaskStatus status = TaskStatus.todo,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
  }) async {
    _setLoading(true);
    final task = Task(
      id: const Uuid().v4(),
      userId: userId,
      projectId: projectId,
      title: title,
      description: description,
      status: status,
      priority: priority,
      dueDate: dueDate,
    );

    try {
      await StorageService.instance.saveTask(task);
      _tasks.add(task);
      _tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateTask(Task task) async {
    _setLoading(true);
    try {
      await StorageService.instance.saveTask(task);
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
      } else {
        _tasks.add(task);
      }
      _tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteTask(String taskId) async {
    _setLoading(true);
    try {
      await StorageService.instance.deleteTask(taskId);
      _tasks.removeWhere((t) => t.id == taskId);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;
    final current = _tasks[index];
    final updated = Task(
      id: current.id,
      projectId: current.projectId,
      userId: current.userId,
      title: current.title,
      description: current.description,
      status: status,
      priority: current.priority,
      dueDate: current.dueDate,
      createdAt: current.createdAt,
    );
    await updateTask(updated);
  }

  void setStatusFilter(TaskStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setPriorityFilter(TaskPriority? priority) {
    _priorityFilter = priority;
    notifyListeners();
  }

  void clearFilters() {
    _statusFilter = null;
    _priorityFilter = null;
    notifyListeners();
  }
}
