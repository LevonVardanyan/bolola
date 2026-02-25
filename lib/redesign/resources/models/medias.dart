import 'package:json_annotation/json_annotation.dart';

import 'media_category.dart';
import 'media_group.dart';
import 'media_item.dart';

part 'medias.g.dart';

@JsonSerializable()
class Medias {
  List<MediaCategory>? categories;

  Medias({this.categories});

  factory Medias.fromJson(Map<String, dynamic> json) => _$MediasFromJson(json);

  Map<String, dynamic> toJson() => _$MediasToJson(this);

  factory Medias.fromJson2(Map<String, dynamic> json) {
    return Medias(
      categories: (json['categories'] as List?)?.map((e) => MediaCategory.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson2() {
    return {
      'categories': categories?.map((e) => e.toJson()).toList(),
    };
  }

  bool isGroupEmpty(MediaGroup? searchingGroup) {
    for (MediaCategory category in categories ?? []) {
      if (category.alias == searchingGroup?.categoryAlias) {
        for (MediaGroup group in category.groups ?? []) {
          if (group.alias == searchingGroup?.alias) return searchingGroup?.items?.isEmpty == true;
        }
      }
    }
    return false;
  }

  bool hasSomethingEmptyGroup() {
    if (categories?.isEmpty == true) return true;
    for (MediaCategory category in categories ?? []) {
      for (MediaGroup group in category.groups ?? []) {
        if (group.items?.isEmpty == true) {
          return true;
        }
      }
    }
    return false;
  }

  List<MediaGroup> getAllGroups() {
    List<MediaGroup> allGroups = [];
    for (MediaCategory category in categories ?? []) {
      for (MediaGroup group in category.groups ?? []) {
        allGroups.add(group);
      }
    }
    return allGroups;
  }

  List<MediaItem> getAllItems() {
    List<MediaItem> allItems = [];
    for (MediaCategory category in categories ?? []) {
      for (MediaGroup group in category.groups ?? []) {
        allItems.addAll(group.items ?? []);
      }
    }
    return allItems;
  }

  MediaCategory? getCategoryByAlias(String s) {
    for (MediaCategory category in categories ?? []) if (category.alias == s) return category;
    return null;
  }

  void setItemsToGroup(String? groupAlias, String? categoryAlias, List<MediaItem> list) {
    for (MediaCategory category in categories ?? []) {
      if (category.alias == categoryAlias) {
        for (MediaGroup group in category.groups ?? []) {
          if (group.alias == groupAlias) {
            group.items = list;
          }
        }
      }
    }
  }

  bool hasGroup(String? categoryAlias, String? groupAlias) {
    for (MediaCategory category in categories ?? []) {
      if (category.alias == categoryAlias) {
        for (MediaGroup group in category.groups ?? []) {
          if (group.alias == groupAlias) {
            return true;
          }
        }
      }
    }
    return false;
  }

  void addGroupToCategory(String? categoryAlias, MediaGroup mediaGroup) {
    for (MediaCategory category in categories ?? []) {
      if (category.alias == categoryAlias) {
        category.groups?.add(mediaGroup);
      }
    }
  }
}
