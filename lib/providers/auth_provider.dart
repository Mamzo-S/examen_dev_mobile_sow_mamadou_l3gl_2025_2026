import 'package:flutter/material.dart';
import 'package:sunu_task/models/User.dart';
import 'package:sunu_task/services/storage_service.dart';
import 'package:uuid/uuid.dart';

class AuthProvider extends ChangeNotifier {
  // Etat de session + etat UI pour les ecrans auth.
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> init() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Recharge la session persistée si un utilisateur etait connecte.
      _currentUser = await StorageService.instance.getCurrentUser();
    } catch (_) {
      _error = 'Impossible de charger la session utilisateur.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final users = await StorageService.instance.getUsers();
      final normalizedEmail = email.trim().toLowerCase();

      User? foundUser;
      for (final user in users) {
        // Comparaison case-insensitive sur l'email.
        if (user.email.trim().toLowerCase() == normalizedEmail &&
            user.password == password) {
          foundUser = user;
          break;
        }
      }

      if (foundUser == null) {
        _error = 'Email ou mot de passe incorrect.';
        return false;
      }

      _currentUser = foundUser;
      // On persiste seulement l'ID courant, la liste users reste la source de verite.
      await StorageService.instance.setCurrentUser(foundUser);
      return true;
    } catch (_) {
      _error = 'Une erreur est survenue pendant la connexion.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final users = await StorageService.instance.getUsers();
      final normalizedEmail = email.trim().toLowerCase();

      final emailAlreadyUsed = users.any(
        (user) => user.email.trim().toLowerCase() == normalizedEmail,
      );

      if (emailAlreadyUsed) {
        _error = 'Cet email est déjà utilisé.';
        return false;
      }

      final newUser = User(
        // ID unique local pour retrouver l'utilisateur dans SharedPreferences.
        id: const Uuid().v4(),
        name: name.trim(),
        email: normalizedEmail,
        password: password,
      );

      await StorageService.instance.createUser(newUser);
      await StorageService.instance.setCurrentUser(newUser);
      _currentUser = newUser;

      return true;
    } catch (_) {
      _error = 'Une erreur est survenue pendant l\'inscription.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = null;
      await StorageService.instance.setCurrentUser(null);
    } catch (_) {
      _error = 'Impossible de se déconnecter pour le moment.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({String? name, String? email}) async {
    if (_currentUser == null) {
      _error = 'Aucun utilisateur connecté.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final users = await StorageService.instance.getUsers();

      final normalizedEmail = email?.trim().toLowerCase();
      if (normalizedEmail != null && normalizedEmail.isNotEmpty) {
        final alreadyUsed = users.any(
          (user) =>
              user.id != _currentUser!.id &&
              user.email.trim().toLowerCase() == normalizedEmail,
        );

        if (alreadyUsed) {
          _error = 'Cet email est déjà utilisé par un autre compte.';
          return;
        }
      }

      final updatedUser = User(
        // On reconstruit l'objet au lieu d'utiliser copyWith car ton User actuel
        // contient un copyWith incorrect (email/password).
        id: _currentUser!.id,
        name: name?.trim().isNotEmpty == true ? name!.trim() : _currentUser!.name,
        email: normalizedEmail?.isNotEmpty == true
            ? normalizedEmail!
            : _currentUser!.email,
        password: _currentUser!.password,
        avatar: _currentUser!.avatar,
        createdAt: _currentUser!.createdAt,
      );

      await StorageService.instance.updateUser(updatedUser);
      await StorageService.instance.setCurrentUser(updatedUser);
      _currentUser = updatedUser;
    } catch (_) {
      _error = 'Impossible de mettre à jour le profil.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
