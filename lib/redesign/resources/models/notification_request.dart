import 'package:json_annotation/json_annotation.dart';

part 'notification_request.g.dart';

@JsonSerializable()
class NotificationRequest {
  final String topic;
  final String title;
  final String message;
  final Map<String, dynamic>? data;

  NotificationRequest({
    required this.topic,
    required this.title,
    required this.message,
    this.data,
  });

  factory NotificationRequest.fromJson(Map<String, dynamic> json) => _$NotificationRequestFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationRequestToJson(this);
} 