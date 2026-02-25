import 'package:json_annotation/json_annotation.dart';
import 'media_item.dart';
import 'user.dart';

part 'favorites_response.g.dart';

@JsonSerializable()
class AddToFavoritesResponse {
  final String message;
  final User user;
  final String addedItem;

  AddToFavoritesResponse({
    required this.message,
    required this.user,
    required this.addedItem,
  });

  factory AddToFavoritesResponse.fromJson(Map<String, dynamic> json) =>
      _$AddToFavoritesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AddToFavoritesResponseToJson(this);
}

@JsonSerializable()
class RemoveFromFavoritesResponse {
  final String message;
  final User user;
  final String removedItem;

  RemoveFromFavoritesResponse({
    required this.message,
    required this.user,
    required this.removedItem,
  });

  factory RemoveFromFavoritesResponse.fromJson(Map<String, dynamic> json) =>
      _$RemoveFromFavoritesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$RemoveFromFavoritesResponseToJson(this);
}

@JsonSerializable()
class GetUserFavoritesResponse {
  final List<String> favorites;
  final List<MediaItem> items;

  GetUserFavoritesResponse({
    required this.favorites,
    required this.items,
  });

  factory GetUserFavoritesResponse.fromJson(Map<String, dynamic> json) =>
      _$GetUserFavoritesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$GetUserFavoritesResponseToJson(this);
}

@JsonSerializable()
class CheckFavoriteResponse {
  final String itemAlias;
  final bool isFavorite;

  CheckFavoriteResponse({
    required this.itemAlias,
    required this.isFavorite,
  });

  factory CheckFavoriteResponse.fromJson(Map<String, dynamic> json) =>
      _$CheckFavoriteResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CheckFavoriteResponseToJson(this);
}

@JsonSerializable()
class ClearFavoritesResponse {
  final String message;
  final List<String> favorites;
  final int favoritesCount;

  ClearFavoritesResponse({
    required this.message,
    required this.favorites,
    required this.favoritesCount,
  });

  factory ClearFavoritesResponse.fromJson(Map<String, dynamic> json) =>
      _$ClearFavoritesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ClearFavoritesResponseToJson(this);
} 