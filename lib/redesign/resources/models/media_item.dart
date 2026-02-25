import 'dart:core';

import 'package:json_annotation/json_annotation.dart';

part 'media_item.g.dart';

@JsonSerializable()
class MediaItem {
  List<String>? keywords;
  List<String>? allKeywords;
  List<String>? relatedKeywords;
  bool? isFavorite;
  String? name;
  int? shareCount;
  String? audioUrl;
  String? videoUrl;
  String? sourceUrl;
  String? imageUrl;
  String? groupAlias;
  String? categoryAlias;
  String? alias;
  String? fileName;
  int? ordering;
  List<String>? suggestedKeywords;

  MediaItem({
    this.keywords,
    this.relatedKeywords,
    this.isFavorite = false,
    this.name,
    this.shareCount = 0,
    this.ordering = 0,
    this.groupAlias,
    this.categoryAlias,
    this.alias,
    this.fileName,
    this.audioUrl,
    this.videoUrl,
    this.sourceUrl,
    this.imageUrl,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) => _$MediaItemFromJson(json);

  Map<String, dynamic> toJson() => _$MediaItemToJson(this);

  bool operator ==(dynamic other) {
    return (other.alias == alias);
  }

  MediaItem.fromMap(Map map) {
    name = map['name'];
    alias = map['alias'];
    fileName = map['fileName'];
    ordering = map['ordering'] ?? 0;
    shareCount = map['shareCount'] ?? 0;
    audioUrl = map['audioUrl'];
    videoUrl = map['videoUrl'];
    sourceUrl = map['sourceUrl'] ?? "";
    imageUrl = map['imageUrl'];
    keywords = List<String>.from(map["keywords"] ?? {});
    relatedKeywords = List<String>.from(map["relatedKeywords"] ?? {});
  }

  MediaItem.fromDBMap(Map map) {
    name = map['name'];
    alias = map['alias'];
    fileName = map['fileName'];
    groupAlias = map['groupAlias'];
    ordering = map['ordering'] ?? 0;
    categoryAlias = map['categoryAlias'];
    shareCount = map['shareCount'] ?? 0;
    audioUrl = map['audioUrl'];
    videoUrl = map['videoUrl'];
    sourceUrl = map['sourceUrl'] ?? "";
    imageUrl = map['imageUrl'];
    isFavorite = map['isFavorite'] == 1;
    keywords = map["keywords"] != null && map["keywords"].isNotEmpty ? map["keywords"].split(', ') : null;
    relatedKeywords = map["relatedKeywords"] != null && map["relatedKeywords"].isNotEmpty ? map["relatedKeywords"].split(', ') : null;
    allKeywords = map["allKeywords"] != null && map["allKeywords"].isNotEmpty ? map["allKeywords"].split(', ') : null;
  }

  Map<String, dynamic> toMap() {
    return {
      "shareCount": shareCount,
      "name": name,
      "alias": alias,
      "fileName": fileName,
      "ordering": ordering,
      "audioUrl": audioUrl,
      "videoUrl": videoUrl,
      "sourceUrl": sourceUrl,
      "imageUrl": imageUrl,
      "keywords": keywords,
      "relatedKeywords": relatedKeywords,
    };
  }

  Map<String, dynamic> toDBMap() {
    return {
      "alias": alias,
      "fileName": fileName,
      "shareCount": shareCount,
      "name": name,
      "groupAlias": groupAlias,
      "categoryAlias": categoryAlias,
      "ordering": ordering,
      "audioUrl": audioUrl,
      "videoUrl": videoUrl,
      "sourceUrl": sourceUrl,
      "imageUrl": imageUrl,
      "isFavorite": isFavorite == true ? 1 : 0,
      "keywords": keywords?.isNotEmpty == true ? keywords!.join(', ') : null,
      "relatedKeywords": relatedKeywords?.isNotEmpty == true ? relatedKeywords!.join(', ') : null,
      "allKeywords": allKeywords?.isNotEmpty == true ? allKeywords!.join(', ') : null,
    };
  }
}
