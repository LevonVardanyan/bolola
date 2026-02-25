// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'top_chart.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TopChart _$TopChartFromJson(Map<String, dynamic> json) => TopChart(
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TopChartToJson(TopChart instance) => <String, dynamic>{
      'items': instance.items,
    };
