// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MediaGroup _$MediaGroupFromJson(Map<String, dynamic> json) => MediaGroup(
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      sortingTypes: (json['sortingTypes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      subGroups: (json['subGroups'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      name: json['name'] as String?,
      count: (json['count'] as num?)?.toInt(),
      iconUrl: json['iconUrl'] as String?,
      alias: json['alias'] as String?,
      categoryAlias: json['categoryAlias'] as String?,
      ordering: (json['ordering'] as num?)?.toInt() ?? 0,
      isNewGroup: (json['isNewGroup'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$MediaGroupToJson(MediaGroup instance) =>
    <String, dynamic>{
      'items': instance.items,
      'sortingTypes': instance.sortingTypes,
      'subGroups': instance.subGroups,
      'name': instance.name,
      'count': instance.count,
      'iconUrl': instance.iconUrl,
      'alias': instance.alias,
      'categoryAlias': instance.categoryAlias,
      'ordering': instance.ordering,
      'isNewGroup': instance.isNewGroup,
    };
