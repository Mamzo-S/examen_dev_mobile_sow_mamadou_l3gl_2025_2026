import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sunu_task/models/project.dart';
import 'package:sunu_task/models/User.dart';
import 'package:sunu_task/models/task.dart';
import 'package:uuid/uuid.dart';

/**
 * Pattern Singleton:
 * Pour avoir une seule instance
 */
class StorageService {
  //===== Singleton ==========
  /// Instance Unique (privee)
  static StorageService? _instance;

  /// Getter pour acceder a l'instance
  static StorageService get instance {
    _instance ??= StorageService._();
    return _instance!;
  }

  /// Constructeur prive
  StorageService._();

  //===== SharedPreferences ==========
  /**
   * SharedPreferences utilise des opérations asynchrones
   * car il lit/ecrtit sur le disque
   *
   * Le mot-cle await attend que l'operation se termine
   * La fonction doit etre marque async et retourner un Future
   * Les variables doivent être marqué par late
   */
  late SharedPreferences _prefs;

  /// Indicateur d'initialisation
  bool _initialized = false;

  Future<void> init() async {
    if(_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  // ======== Cles de Stockage =========
  static const String _keyOnboardingConmplete = 'onboarding_complete';
  static const String _keyUsers = 'users';
  static const String _keyCurrentUserId = 'current_user_id';
  static const String _keyProjects = 'projects';
  static const String _keyTasks = 'tasks';

  bool get isOnboardingComplete {
    return _prefs.getBool(_keyOnboardingConmplete) ?? false;
  }

  Future<void> setOnboardingComplete(bool value) async {
    await _prefs.setBool(_keyOnboardingConmplete, value);
  }

  // ===== Recuperer tous les users =====
  Future<List<User>> getUsers() async {
    final data = _prefs.getString(_keyUsers);

    if (data == null) {
      return [];
    }

    final List list = jsonDecode(data);

    return list.map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      map['avatar'] = map['avatar'] ?? '';
      map['createdAt'] =
          (map['createdAt'] ?? DateTime.now().toIso8601String()).toString();
      return User.fromMap(map);
    }).toList();
  }

  // ===== Ajouter un user =====
  Future<void> createUser(User user) async {
    final users = await getUsers();

    final userToSave = user.id.trim().isEmpty
        ? User(
            id: const Uuid().v4(),
            name: user.name,
            email: user.email,
            password: user.password,
            avatar: user.avatar,
            createdAt: user.createdAt,
          )
        : user;

    users.add(userToSave);

    final encoded = jsonEncode(
      users.map((u) => _toSafeMap(u)).toList(),
    );

    await _prefs.setString(_keyUsers, encoded);
  }

  // ===== Modifier un user =====
  Future<void> updateUser(User user) async {
    final users = await getUsers();
    final userToSave = user.id.trim().isEmpty
        ? User(
            id: const Uuid().v4(),
            name: user.name,
            email: user.email,
            password: user.password,
            avatar: user.avatar,
            createdAt: user.createdAt,
          )
        : user;

    bool found = false;
    for (int i = 0; i < users.length; i++) {
      if (users[i].id == userToSave.id) {
        users[i] = userToSave;
        found = true;
        break;
      }
    }
    if (!found) {
      users.add(userToSave);
    }

    final encoded = jsonEncode(
      users.map((u) => _toSafeMap(u)).toList(),
    );

    await _prefs.setString(_keyUsers, encoded);
  }

  // ===== Sauvegarder l'utilisateur connecté =====
  Future<void> setCurrentUser(User? user) async {
    if (user == null) {
      await _prefs.remove(_keyCurrentUserId);
      return;
    }
    await _prefs.setString(_keyCurrentUserId, user.id);
  }

  // ===== Recuperer l'utilisateur connecté =====
  Future<User?> getCurrentUser() async {
    final id = _prefs.getString(_keyCurrentUserId);

    if (id == null) {
      return null;
    }

    final users = await getUsers();

    for (var user in users) {
      if (user.id == id) {
        return user;
      }
    }
    return null;
  }

  Map<String, dynamic> _toSafeMap(User user) {
    final map = Map<String, dynamic>.from(user.toMap());
    map['avatar'] = map['avatar'] ?? '';
    final createdAt = map['createdAt'];
    map['createdAt'] = createdAt is DateTime
        ? createdAt.toIso8601String()
        : (createdAt ?? DateTime.now().toIso8601String()).toString();
    return map;
  }

  // =====================
  // crud project
  // =====================

  Future<List<Project>> getProjects() async {
    final data = _prefs.getString(_keyProjects);
    if (data == null || data.trim().isEmpty) return [];

    try {
      final decoded = jsonDecode(data);
      if (decoded is! List) return [];

      return decoded.map((e) {
        return Project.fromMap(Map<String, dynamic>.from(e as Map));
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Project>> getProjectsByUserId(String userId) async {
    final projects = await getProjects();
    return projects.where((p) => p.userId == userId).toList();
  }

  Future<Project?> getProjectById(String projectId) async {
    final projects = await getProjects();
    for (final project in projects) {
      if (project.id == projectId) return project;
    }
    return null;
  }

  Future<void> createProject(Project project) async {
    final projects = await getProjects();

    final projectToSave = project.id.trim().isEmpty
        ? Project(
            id: const Uuid().v4(),
            userId: project.userId,
            name: project.name,
            description: project.description,
            colorValue: project.colorValue,
            createdAt: project.createdAt,
          )
        : project;

    projects.add(projectToSave);
    await saveProjects(projects);
  }

  Future<void> updateProject(Project project) async {
    final projects = await getProjects();

    final projectToSave = project.id.trim().isEmpty
        ? Project(
            id: const Uuid().v4(),
            userId: project.userId,
            name: project.name,
            description: project.description,
            colorValue: project.colorValue,
            createdAt: project.createdAt,
          )
        : project;

    bool found = false;
    for (int i = 0; i < projects.length; i++) {
      if (projects[i].id == projectToSave.id) {
        projects[i] = projectToSave;
        found = true;
        break;
      }
    }

    if (!found) {
      projects.add(projectToSave);
    }

    await saveProjects(projects);
  }

  Future<void> saveProjects(List<Project> projects) async {
    final encoded = jsonEncode(projects.map((p) => p.toMap()).toList());
    await _prefs.setString(_keyProjects, encoded);
  }

  Future<void> deleteProject(String projectId) async {
    final projects = await getProjects();
    projects.removeWhere((p) => p.id == projectId);
    await saveProjects(projects);
    await deleteTasksByProjectId(projectId);
  }

  // ==================
  // crud task
  // ==================

  Future<List<Task>> getTasks() async {
    final data = _prefs.getString(_keyTasks);
    if (data == null || data.trim().isEmpty) return [];

    try {
      final decoded = jsonDecode(data);
      if (decoded is! List) return [];

      return decoded.map((e) {
        return Task.fromMap(Map<String, dynamic>.from(e as Map));
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTasks(List<Task> tasks) async {
    final encoded = jsonEncode(tasks.map((t) => t.toMap()).toList());
    await _prefs.setString(_keyTasks, encoded);
  }

  Future<void> deleteTasksByProjectId(String projectId) async {
    final tasks = await getTasks();
    tasks.removeWhere((t) => t.projectId == projectId);
    await saveTasks(tasks);
  }
}
