import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_error_body.freezed.dart';
part 'api_error_body.g.dart';

@freezed
class ApiErrorBody with _$ApiErrorBody {
  const factory ApiErrorBody({
    String? detail,
    String? message,
  }) = _ApiErrorBody;

  factory ApiErrorBody.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorBodyFromJson(json);
}
