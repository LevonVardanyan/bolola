import 'media_item.dart';
import 'dart:core';

import 'package:json_annotation/json_annotation.dart';

part 'media_group.g.dart';

@JsonSerializable()
class MediaGroup {
  List<MediaItem>? items;
  List<String>? sortingTypes;
  List<String>? subGroups;
  String? name;
  int? count;
  String? iconUrl;
  String? alias;
  String? categoryAlias;
  int? ordering;
  int? isNewGroup;

  MediaGroup({
    this.items,
    this.sortingTypes,
    this.subGroups,
    this.name,
    this.count,
    this.iconUrl,
    this.alias,
    this.categoryAlias,
    this.ordering = 0,
    this.isNewGroup = 0,
  });

  factory MediaGroup.fromJson(Map<String, dynamic> json) => _$MediaGroupFromJson(json);

  Map<String, dynamic> toJson() => _$MediaGroupToJson(this);

  factory MediaGroup.fromJson2(Map<String, dynamic> json) {
    return MediaGroup(
      name: json['name'],
      alias: json['alias'],
      categoryAlias: json['categoryAlias'],
      iconUrl: json['iconUrl'],
      count: json['count'],
      ordering: json['ordering'],
      isNewGroup: json['isNew'],
      sortingTypes: (json['sortingTypes'] as List?)?.map((e) => e.toString()).toList(),
      subGroups: (json['subGroups'] as List?)?.map((e) => e.toString()).toList(),
      items: (json['audios'] as List?)?.map((e) => MediaItem.fromJson(e as Map<String, dynamic>)).toList() ??
          (json['videos'] as List?)?.map((e) => MediaItem.fromJson(e as Map<String, dynamic>)).toList() ??
          (json['items'] as List?)?.map((e) => MediaItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson2() {
    return {
      'name': name,
      'alias': alias,
      'categoryAlias': categoryAlias,
      'iconUrl': iconUrl,
      'count': count,
      'ordering': ordering,
      'isNew': isNewGroup,
      'sortingTypes': sortingTypes,
      'subGroups': subGroups,
      'items': items?.map((e) => e.toJson()).toList(),
    };
  }

  MediaGroup.itemsFromMap(Map map) {
    List<dynamic> audios = map['items'];
    for (int i = 0; i < audios.length; i++) {
      items?.add(MediaItem.fromMap(audios[i]));
    }
  }

  MediaGroup.dataFromMap(Map map) {
    name = map['name'];
    categoryAlias = map['categoryAlias'];
    alias = map['alias'];
    iconUrl = map['iconUrl'];
    count = map['count'];
    ordering = map['ordering'];
    isNewGroup = map['isNew'];
    sortingTypes = List<String>.from(map["sortingTypes"] ?? {});
    subGroups = List<String>.from(map["subGroups"] ?? {});
  }

  MediaGroup.dataFromDBMap(Map map) {
    name = map['name'];
    categoryAlias = map['categoryAlias'];
    alias = map['alias'];
    iconUrl = map['iconUrl'];
    count = map['count'];
    ordering = map['ordering'];
    isNewGroup = map['isNew'];
    sortingTypes = map["sortingTypes"] == "" || map["sortingTypes"] == null ? null : map["sortingTypes"]?.split(', ');
  }

  Map<String, dynamic> dataToDBMap() {
    return {
      "name": name,
      "iconUrl": iconUrl,
      "categoryAlias": categoryAlias,
      "alias": alias,
      "ordering": ordering,
      "count": count,
      "isNew": isNewGroup,
      "sortingTypes": sortingTypes?.join(', '),
    };
  }

  @override
  Map<String, dynamic> itemsToMap() {
    return {"items": List.from(items!.map((e) => e.toMap()))};
  }

  bool operator ==(dynamic other) {
    return (other.alias == alias);
  }
}
