import 'package:url_launcher/url_launcher.dart';

String? resolveLeaveAttachmentUrl(String? raw, String apiBaseUrl) {
  if (raw == null) {
    return null;
  }
  final String value = raw.trim();
  if (value.isEmpty) {
    return null;
  }
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }
  final String origin = apiBaseUrl.replaceFirst(RegExp(r'/api/v1/?$'), '');
  if (value.startsWith('/')) {
    return '$origin$value';
  }
  return '$origin/$value';
}

Future<bool> openLeaveAttachment(String url) async {
  final Uri? uri = Uri.tryParse(url);
  if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
    return false;
  }
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

String leaveDaysLabel(int days) {
  return days == 1 ? '1 day' : '$days days';
}
