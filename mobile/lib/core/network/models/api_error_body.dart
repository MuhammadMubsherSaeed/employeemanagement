/// Defensive parser for API error payloads.
///
/// Expected (but not required) shape:
/// `{ "success": false, "message": "...", "code": "...", "errors": {} }`
class ApiErrorBody {
  const ApiErrorBody({
    this.success,
    this.message,
    this.code,
    this.errors,
    this.detail,
  });

  final bool? success;
  final String? message;
  final String? code;
  final Map<String, dynamic>? errors;
  final String? detail;

  String? get displayMessage {
    final String? primary = _nonEmpty(message) ?? _nonEmpty(detail);
    return primary;
  }

  static ApiErrorBody fromJson(dynamic data) {
    if (data is! Map) {
      if (data is String && data.trim().isNotEmpty && !_looksLikeHtml(data)) {
        return ApiErrorBody(message: data.trim());
      }
      return const ApiErrorBody();
    }

    final Map<String, dynamic> json = Map<String, dynamic>.from(data);
    return ApiErrorBody(
      success: json['success'] is bool ? json['success'] as bool : null,
      message: _asString(json['message']),
      code: _asString(json['code']),
      detail: _asString(json['detail']),
      errors: _asMap(json['errors']),
    );
  }

  static String? _asString(dynamic value) {
    if (value is String) {
      return _nonEmpty(value);
    }
    if (value is List && value.isNotEmpty) {
      return _asString(value.first);
    }
    return null;
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map && value.isNotEmpty) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  static String? _nonEmpty(String? value) {
    final String? trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  static bool _looksLikeHtml(String value) {
    return value.contains('<html') || value.contains('<HTML');
  }
}
