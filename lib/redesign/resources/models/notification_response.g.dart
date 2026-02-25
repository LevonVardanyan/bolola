// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationResponse _$NotificationResponseFromJson(
        Map<String, dynamic> json) =>
    NotificationResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      messageId: json['messageId'] as String?,
      statusCode: (json['statusCode'] as num?)?.toInt(),
      data: json['data'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$NotificationResponseToJson(
        NotificationResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'messageId': instance.messageId,
      'statusCode': instance.statusCode,
      'data': instance.data,
    };
