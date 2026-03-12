import 'package:flutter/material.dart';
import 'package:sunu_task/models/project.dart';
import 'package:sunu_task/services/storage_service.dart';
import 'package:uuid/uuid.dart';

class ProjectProvider extends ChangeNotifier {
  List<Project> _projects = [];
  Project? _selectedProject;
  bool _isLoading = false;

  List<Project> get projects => _projects;
  Project? get selectedProject => _selectedProject;
  int get projectCount => _projects.length;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  Future<void> loadProjects(String userId) async {
    _setLoading(true);

    try {
      _projects = await StorageService.instance.getProjectsByUserId(userId);
      _projects.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (_selectedProject != null) {
        final selectedId = _selectedProject!.id;
        _selectedProject =
        _projects.where((p) => p.id == selectedId).isNotEmpty
            ? _projects.firstWhere((p) => p.id == selectedId)
            : null;
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createProject({
    required String userId,
    required String name,
    String? description,
    required int colorValue,
  }) async {
    _setLoading(true);
    final project = Project(
      id: const Uuid().v4(),
      userId: userId,
      name: name,
      description: description,
      colorValue: colorValue,
    );

    try {
      await StorageService.instance.createProject(project);
      _projects.insert(0, project);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProject(Project project) async {
    _setLoading(true);
    try {
      await StorageService.instance.updateProject(project);
      final index = _projects.indexWhere((p) => p.id == project.id);
      if (index != -1) {
        _projects[index] = project;
      } else {
        _projects.add(project);
      }
      _projects.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (_selectedProject?.id == project.id) {
        _selectedProject = project;
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteProject(String projectId) async {
    _setLoading(true);
    try {
      await StorageService.instance.deleteProject(projectId);
      _projects.removeWhere((p) => p.id == projectId);
      if (_selectedProject?.id == projectId) {
        _selectedProject = null;
      }
    } finally {
      _setLoading(false);
    }
  }

  void selectProject(Project? project) {
    _selectedProject = project;
    notifyListeners();
  }
}
