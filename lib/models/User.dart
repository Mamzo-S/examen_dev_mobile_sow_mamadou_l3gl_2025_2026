/**
 * Les modeles sont immutables(final) pour éviter les
 * modifications et facliter la gestion d'etat
 */
class User {
  /// Identifiant unique de l'utilisateur (UUID)
 final String id;

 /// Nom complet de l'utilisateur
 final String name;

 final String email;

 final String password;

 final String? avatar;

 final DateTime createdAt;

 /// Constructeur
 User({
   required this.id,
   required this.name,
   required this.email,
   required this.password,
   this.avatar,
   DateTime? createdAt,
}) : createdAt = createdAt ?? DateTime.now();

 /**
  * Crée une copie de l'utilisateur avec des champs modifies
  * Ex: final updatedUser = user.copyWith(name: 'Babacar NDIAYE')
  */
 User copyWith({
   String? id,
   String? name,
   String? email,
   String? password,
   String? avatar,
   DateTime? createdAt,
}) {
   return User(
       id: id ?? this.id,
       name: name ?? this.name,
       email: email ?? this.email,
       password: password ?? this.password,
       avatar: avatar ?? this.avatar,
       createdAt: createdAt ?? this.createdAt
   );
 }

 /**
  * Convertir l'utilisateur en Map pour la serialisation
  * Utile pour sauvegarder dans shared_preferences ou envoyer a une API
  */
 Map<String, dynamic> toMap() {
   return {
     'id': id,
     'name': name,
     'email': email,
     'password': password,
     'avatar': avatar,
     'createdAt': createdAt
   };
 }

 /**
  * Créer un utilisateur à l'aide du constructeur factory depuis un Map
  */
 factory User.fromMap(Map<String, dynamic> map) {
   return User(
       id: map['id'] as String,
       name: map['name'] as String,
       email: map['email'] as String,
       password: map['password'] as String,
       avatar: map['avatar'] as String,
       createdAt: DateTime.parse(map['createdAt'] as String)
   );
 }

 @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email)';
  }
}