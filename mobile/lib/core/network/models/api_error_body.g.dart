// Generated locally to match json_serializable for ApiErrorBody.
part of 'api_error_body.dart';

ApiErrorBody _$ApiErrorBodyFromJson(Map<String, dynamic> json) {
  return _$ApiErrorBodyImpl(
    detail: json['detail'] as String?,
    message: json['message'] as String?,
  );
}

Map<String, dynamic> _$ApiErrorBodyToJson(_ApiErrorBody instance) =>
    <String, dynamic>{
      'detail': instance.detail,
      'message': instance.message,
    };
