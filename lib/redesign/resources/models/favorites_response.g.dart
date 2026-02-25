// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorites_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddToFavoritesResponse _$AddToFavoritesResponseFromJson(
        Map<String, dynamic> json) =>
    AddToFavoritesResponse(
      message: json['message'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      addedItem: json['addedItem'] as String,
    );

Map<String, dynamic> _$AddToFavoritesResponseToJson(
        AddToFavoritesResponse instance) =>
    <String, dynamic>{
      'message': instance.message,
      'user': instance.user,
      'addedItem': instance.addedItem,
    };

RemoveFromFavoritesResponse _$RemoveFromFavoritesResponseFromJson(
        Map<String, dynamic> json) =>
    RemoveFromFavoritesResponse(
      message: json['message'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      removedItem: json['removedItem'] as String,
    );

Map<String, dynamic> _$RemoveFromFavoritesResponseToJson(
        RemoveFromFavoritesResponse instance) =>
    <String, dynamic>{
      'message': instance.message,
      'user': instance.user,
      'removedItem': instance.removedItem,
    };

GetUserFavoritesResponse _$GetUserFavoritesResponseFromJson(
        Map<String, dynamic> json) =>
    GetUserFavoritesResponse(
      favorites:
          (json['favorites'] as List<dynamic>).map((e) => e as String).toList(),
      items: (json['items'] as List<dynamic>)
          .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$GetUserFavoritesResponseToJson(
        GetUserFavoritesResponse instance) =>
    <String, dynamic>{
      'favorites': instance.favorites,
      'items': instance.items,
    };

CheckFavoriteResponse _$CheckFavoriteResponseFromJson(
        Map<String, dynamic> json) =>
    CheckFavoriteResponse(
      itemAlias: json['itemAlias'] as String,
      isFavorite: json['isFavorite'] as bool,
    );

Map<String, dynamic> _$CheckFavoriteResponseToJson(
        CheckFavoriteResponse instance) =>
    <String, dynamic>{
      'itemAlias': instance.itemAlias,
      'isFavorite': instance.isFavorite,
    };

ClearFavoritesResponse _$ClearFavoritesResponseFromJson(
        Map<String, dynamic> json) =>
    ClearFavoritesResponse(
      message: json['message'] as String,
      favorites:
          (json['favorites'] as List<dynamic>).map((e) => e as String).toList(),
      favoritesCount: (json['favoritesCount'] as num).toInt(),
    );

Map<String, dynamic> _$ClearFavoritesResponseToJson(
        ClearFavoritesResponse instance) =>
    <String, dynamic>{
      'message': instance.message,
      'favorites': instance.favorites,
      'favoritesCount': instance.favoritesCount,
    };
