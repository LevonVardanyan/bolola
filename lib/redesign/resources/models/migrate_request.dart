import 'package:json_annotation/json_annotation.dart';
import 'package:politicsstatements/redesign/resources/models/media_item.dart';

part 'migrate_request.g.dart';

@JsonSerializable()
class MigrateRequest {
  String? email;

  MigrateRequest({
    this.email,
  });

  factory MigrateRequest.fromJson(Map<String, dynamic> json) => _$MigrateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MigrateRequestToJson(this);
}
