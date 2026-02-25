class SourceLinks {
  List<SourceLinkItem>? sources;

  SourceLinks({this.sources});

  SourceLinks.fromMap(Map map) {
    List<dynamic> audios = map['sources'];
    for (int i = 0; i < audios.length; i++) {
      sources?.add(SourceLinkItem.fromMap(audios[i]));
    }
  }

  Map<String, dynamic> toMap() {
    return {"audios": List.from(sources!.map((e) => e.toMap()))};
  }
}

class SourceLinkItem {
  String? name;
  String? url;

  SourceLinkItem({this.name, this.url});

  SourceLinkItem.fromMap(Map map) {
    url = map["url"];
    name = map["name"];
  }

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "url": url,
    };
  }
}
