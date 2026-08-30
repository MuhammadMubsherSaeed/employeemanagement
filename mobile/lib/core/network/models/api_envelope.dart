/// Parses `{ success, message, data }` without assuming a rigid schema.
class ApiEnvelope {
  const ApiEnvelope({
    required this.success,
    this.message,
    this.data,
  });

  final bool success;
  final String? message;
  final Object? data;

  static ApiEnvelope parse(dynamic raw) {
    if (raw is! Map) {
      return const ApiEnvelope(success: false);
    }
    final Map<String, dynamic> json = Map<String, dynamic>.from(raw);
    return ApiEnvelope(
      success: json['success'] == true,
      message: json['message'] is String ? json['message'] as String : null,
      data: json['data'],
    );
  }

  Map<String, dynamic> requireDataMap() {
    if (data is Map) {
      return Map<String, dynamic>.from(data as Map);
    }
    throw const FormatException('API response did not include a data object.');
  }
}
