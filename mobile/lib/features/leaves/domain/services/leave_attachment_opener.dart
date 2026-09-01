import 'package:url_launcher/url_launcher.dart';

bool leaveRequestHasAttachment(String? raw) {
  return raw != null && raw.trim().isNotEmpty;
}

/// Public http(s) URLs only. Relative/media paths are private and must be
/// downloaded through the authenticated leave attachment endpoint.
String? resolveLeaveAttachmentUrl(String? raw, String apiBaseUrl) {
  if (raw == null) {
    return null;
  }
  final String value = raw.trim();
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }
  return null;
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
