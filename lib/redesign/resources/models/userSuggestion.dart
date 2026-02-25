import 'media_item.dart';

class UserSuggestion {
  List<String>? messages;
  String? itemAlias;
  String? groupAlias;
  String? categoryAlias;
  String? mediaType;

  bool isThisForMediaItem(MediaItem item) {
    return item.alias == itemAlias && item.groupAlias == groupAlias && item.categoryAlias == categoryAlias;
  }

  UserSuggestion({this.messages, this.itemAlias, this.groupAlias, this.categoryAlias, this.mediaType});

  UserSuggestion.fromMap(Map map) {
    if (map.containsKey("messages")) {
      messages = List<String>.from(map["messages"] ?? {});
    } else {
      messages = [];
    }
    itemAlias = map["itemAlias"] ?? "";
    groupAlias = map["groupAlias"] ?? "";
    categoryAlias = map["categoryAlias"] ?? "";
    mediaType = map["mediaType"] ?? "";
  }

  Map<String, dynamic> toMap() {
    return {
      "messages": messages,
      "itemAlias": itemAlias,
      "groupAlias": groupAlias,
      "categoryAlias": categoryAlias,
      "mediaType": mediaType,
    };
  }
}
