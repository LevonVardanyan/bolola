class UserMessage {
  List<String>? messages;
  List<String>? links;
  String? userName;
  String? fcmToken;
  String? platform;
  String? deviceId;
  DateTime? sendingDate;

  UserMessage({
    this.messages, 
    this.userName, 
    this.fcmToken, 
    this.links, 
    this.platform, 
    this.deviceId, 
    this.sendingDate
  });

  UserMessage.fromMap(Map map) {
    fcmToken = map["fcmToken"];
    platform = map["platform"];
    userName = map["userName"];
    deviceId = map["deviceId"];
    
    // Parse sending date
    if (map.containsKey("sendingDate")) {
      final dateValue = map["sendingDate"];
      if (dateValue is DateTime) {
        sendingDate = dateValue;
      } else if (dateValue is String) {
        sendingDate = DateTime.tryParse(dateValue);
      } else if (dateValue is int) {
        sendingDate = DateTime.fromMillisecondsSinceEpoch(dateValue);
      }
    }
    
    if (map.containsKey("messages")) {
      messages = List<String>.from(map["messages"] ?? {});
    } else {
      messages = [];
    }
    if (map.containsKey("links")) {
      links = List<String>.from(map["links"] ?? {});
    } else {
      links = [];
    }
  }

  Map<String, dynamic> toMap() {
    return {
      "messages": messages,
      "links": links,
      "fcmToken": fcmToken,
      "platform": platform,
      "userName": userName,
      "deviceId": deviceId,
      "sendingDate": sendingDate?.millisecondsSinceEpoch,
    };
  }
}
