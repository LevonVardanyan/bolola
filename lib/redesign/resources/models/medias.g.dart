// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medias.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Medias _$MediasFromJson(Map<String, dynamic> json) => Medias(
      categories: (json['categories'] as List<dynamic>?)
          ?.map((e) => MediaCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MediasToJson(Medias instance) => <String, dynamic>{
      'categories': instance.categories,
    };
