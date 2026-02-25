// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MediaItem _$MediaItemFromJson(Map<String, dynamic> json) => MediaItem(
      keywords: (json['keywords'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      relatedKeywords: (json['relatedKeywords'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      isFavorite: json['isFavorite'] as bool? ?? false,
      name: json['name'] as String?,
      shareCount: (json['shareCount'] as num?)?.toInt() ?? 0,
      ordering: (json['ordering'] as num?)?.toInt() ?? 0,
      groupAlias: json['groupAlias'] as String?,
      categoryAlias: json['categoryAlias'] as String?,
      alias: json['alias'] as String?,
      fileName: json['fileName'] as String?,
      audioUrl: json['audioUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      sourceUrl: json['sourceUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
    )
      ..allKeywords = (json['allKeywords'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList()
      ..suggestedKeywords = (json['suggestedKeywords'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList();

Map<String, dynamic> _$MediaItemToJson(MediaItem instance) => <String, dynamic>{
      'keywords': instance.keywords,
      'allKeywords': instance.allKeywords,
      'relatedKeywords': instance.relatedKeywords,
      'isFavorite': instance.isFavorite,
      'name': instance.name,
      'shareCount': instance.shareCount,
      'audioUrl': instance.audioUrl,
      'videoUrl': instance.videoUrl,
      'sourceUrl': instance.sourceUrl,
      'imageUrl': instance.imageUrl,
      'groupAlias': instance.groupAlias,
      'categoryAlias': instance.categoryAlias,
      'alias': instance.alias,
      'fileName': instance.fileName,
      'ordering': instance.ordering,
      'suggestedKeywords': instance.suggestedKeywords,
    };
