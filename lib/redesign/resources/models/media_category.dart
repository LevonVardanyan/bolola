import 'media_group.dart';
import 'dart:core';

import 'package:json_annotation/json_annotation.dart';

part 'media_category.g.dart';

@JsonSerializable()
class MediaCategory {
  List<MediaGroup>? groups;
  String? name;
  String? alias;
  int? ordering;
  List<String>? groupNames;

  MediaCategory({
    this.groups,
    this.name,
    this.alias,
    this.ordering,
    this.groupNames = const [],
  });

  factory MediaCategory.fromJson(Map<String, dynamic> json) => _$MediaCategoryFromJson(json);

  Map<String, dynamic> toJson() => _$MediaCategoryToJson(this);

  set(MediaCategory item) {
    name = item.name;
    alias = item.alias;
    groups = item.groups;
    ordering = item.ordering;
    groupNames = item.groupNames;
  }

  Map<String, dynamic> toDBMap() {
    // Set groupNames from groups using alias list
    List<String> aliasNames = [];
    if (groups != null) {
      for (var group in groups!) {
        if (group.alias != null) {
          aliasNames.add(group.alias!);
        }
      }
    }
    
    return {"name": name, "alias": alias, "ordering": ordering, "groups": aliasNames.join(', ')};
  }


  MediaCategory.fromDBMap(Map map) {
    name = map['name'];
    alias = map['alias'];
    ordering = map['ordering'];
    if (map.containsKey("groups")) {
      groupNames = map["groups"].split(', ');
    }
  }

  bool operator ==(dynamic other) {
    return (other.alias == alias);
  }

}
