import 'package:json_annotation/json_annotation.dart';
import 'package:politicsstatements/redesign/resources/models/media_item.dart';

part 'top_chart.g.dart';

@JsonSerializable()
class TopChart {
  List<MediaItem>? items;

  TopChart({
    this.items,
  });

  factory TopChart.fromJson(Map<String, dynamic> json) => _$TopChartFromJson(json);

  Map<String, dynamic> toJson() => _$TopChartToJson(this);
}
