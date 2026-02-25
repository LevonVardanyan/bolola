import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  @JsonKey(name: 'id')
  String? id;

  @JsonKey(name: 'firebaseUid')
  String? firebaseUid;

  @JsonKey(name: 'name')
  String? name;

  @JsonKey(name: 'email')
  String? email;

  @JsonKey(name: 'photoUrl')
  String? photoUrl;

  @JsonKey(name: 'isAdmin')
  bool? isAdmin;

  @JsonKey(name: 'favorites')
  List<String>? favorites;

  @JsonKey(name: 'createdAt')
  String? createdAt;

  @JsonKey(name: 'updatedAt')
  String? updatedAt;

  @JsonKey(name: 'lastLoginAt')
  String? lastLoginAt;

  @JsonKey(name: 'isActive')
  bool? isActive;

  User({
    this.id,
    this.firebaseUid,
    this.name,
    this.email,
    this.photoUrl,
    this.isAdmin = false,
    this.favorites,
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
    this.isActive = true,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);

  // Helper method to create user from Firebase Auth User
  factory User.fromFirebaseUser(
    String firebaseUid,
    String? displayName,
    String? email,
    String? photoURL,
  ) {
    final now = DateTime.now().toIso8601String();
    return User(
      firebaseUid: firebaseUid,
      name: displayName ?? email?.split('@').first ?? 'User',
      email: email,
      photoUrl: photoURL,
      isAdmin: false,
      favorites: [],
      createdAt: now,
      updatedAt: now,
      lastLoginAt: now,
      isActive: true,
    );
  }

  // Copy with method for updating user data
  User copyWith({
    String? id,
    String? firebaseUid,
    String? name,
    String? email,
    String? photoUrl,
    bool? isAdmin,
    List<String>? favorites,
    String? createdAt,
    String? updatedAt,
    String? lastLoginAt,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      isAdmin: isAdmin ?? this.isAdmin,
      favorites: favorites ?? this.favorites,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
    );
  }

  // Helper methods for favorites management
  bool isFavorite(String itemAlias) {
    return favorites?.contains(itemAlias) ?? false;
  }

  List<String> get favoritesList => favorites ?? [];

  int get favoritesCount => favorites?.length ?? 0;

  @override
  String toString() {
    return 'User{id: $id, firebaseUid: $firebaseUid, name: $name, email: $email, isAdmin: $isAdmin, favoritesCount: $favoritesCount}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          firebaseUid == other.firebaseUid;

  @override
  int get hashCode => id.hashCode ^ firebaseUid.hashCode;
} 