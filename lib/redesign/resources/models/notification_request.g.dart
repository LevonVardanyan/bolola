// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationRequest _$NotificationRequestFromJson(Map<String, dynamic> json) =>
    NotificationRequest(
      topic: json['topic'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$NotificationRequestToJson(
        NotificationRequest instance) =>
    <String, dynamic>{
      'topic': instance.topic,
      'title': instance.title,
      'message': instance.message,
      'data': instance.data,
    };
