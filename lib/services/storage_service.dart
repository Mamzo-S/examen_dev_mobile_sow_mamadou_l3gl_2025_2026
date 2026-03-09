import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sunu_task/models/User.dart';
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
      users.map((u) => u.toMap()).toList(),
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
      users.map((u) => u.toMap()).toList(),
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
}
