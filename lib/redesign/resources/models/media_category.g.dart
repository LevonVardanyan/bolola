// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MediaCategory _$MediaCategoryFromJson(Map<String, dynamic> json) =>
    MediaCategory(
      groups: (json['groups'] as List<dynamic>?)
          ?.map((e) => MediaGroup.fromJson(e as Map<String, dynamic>))
          .toList(),
      name: json['name'] as String?,
      alias: json['alias'] as String?,
      ordering: (json['ordering'] as num?)?.toInt(),
      groupNames: (json['groupNames'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$MediaCategoryToJson(MediaCategory instance) =>
    <String, dynamic>{
      'groups': instance.groups,
      'name': instance.name,
      'alias': instance.alias,
      'ordering': instance.ordering,
      'groupNames': instance.groupNames,
    };
