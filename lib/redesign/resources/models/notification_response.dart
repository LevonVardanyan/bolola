import 'package:json_annotation/json_annotation.dart';

part 'notification_response.g.dart';

@JsonSerializable()
class NotificationResponse {
  final bool success;
  final String message;
  final String? messageId;
  final int? statusCode;
  final Map<String, dynamic>? data;

  NotificationResponse({
    required this.success,
    required this.message,
    this.messageId,
    this.statusCode,
    this.data,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) => _$NotificationResponseFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationResponseToJson(this);
} 