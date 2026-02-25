// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: json['id'] as String?,
      firebaseUid: json['firebaseUid'] as String?,
      name: json['name'] as String?,
      email: json['email'] as String?,
      photoUrl: json['photoUrl'] as String?,
      isAdmin: json['isAdmin'] as bool? ?? false,
      favorites: (json['favorites'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      lastLoginAt: json['lastLoginAt'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'firebaseUid': instance.firebaseUid,
      'name': instance.name,
      'email': instance.email,
      'photoUrl': instance.photoUrl,
      'isAdmin': instance.isAdmin,
      'favorites': instance.favorites,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'lastLoginAt': instance.lastLoginAt,
      'isActive': instance.isActive,
    };
