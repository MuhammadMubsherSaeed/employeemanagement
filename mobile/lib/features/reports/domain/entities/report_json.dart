DateTime? readReportDate(dynamic value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value.toString());
}

String readReportString(dynamic value) {
  if (value == null) {
    return '';
  }
  return value.toString();
}

String? readOptionalReportString(dynamic value) {
  if (value == null) {
    return null;
  }
  final String text = value.toString();
  return text.isEmpty ? null : text;
}

int? readReportInt(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  return int.tryParse(value.toString());
}

Map<String, dynamic>? readReportMap(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

String formatReportDateParam(DateTime value) {
  final DateTime local = DateTime(value.year, value.month, value.day);
  final String month = local.month.toString().padLeft(2, '0');
  final String day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}
