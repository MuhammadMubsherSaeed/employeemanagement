import 'package:intl/intl.dart';

/// Locale-aware formatting. Pass a [DateTime] already in the desired zone.
/// Company timezone conversion will be added when the backend supplies it.
class AppDateFormatter {
  AppDateFormatter._();

  static String date(DateTime value, {String? locale, String? timeZoneName}) {
    return DateFormat.yMMMd(_resolvedLocale(locale)).format(value);
  }

  static String dateRange(
    DateTime start,
    DateTime end, {
    String? locale,
  }) {
    final DateTime a = DateTime(start.year, start.month, start.day);
    final DateTime b = DateTime(end.year, end.month, end.day);
    if (a == b) {
      return date(a, locale: locale);
    }
    return '${date(a, locale: locale)} – ${date(b, locale: locale)}';
  }

  static String time(DateTime value, {String? locale, String? timeZoneName}) {
    return DateFormat.jm(_resolvedLocale(locale)).format(value);
  }

  static String dateTime(
    DateTime value, {
    String? locale,
    String? timeZoneName,
  }) {
    return DateFormat.yMMMd(_resolvedLocale(locale)).add_jm().format(value);
  }

  static String? _resolvedLocale(String? locale) {
    if (locale == null || locale.isEmpty) {
      return null;
    }
    return locale;
  }

  static String relative(DateTime value, {DateTime? now, String? locale}) {
    final DateTime current = now ?? DateTime.now();
    final Duration delta = current.difference(value);

    if (delta.inSeconds.abs() < 60) {
      return 'just now';
    }
    if (delta.inMinutes.abs() < 60) {
      final int minutes = delta.inMinutes.abs();
      return delta.isNegative ? 'in $minutes min' : '$minutes min ago';
    }
    if (delta.inHours.abs() < 24) {
      final int hours = delta.inHours.abs();
      return delta.isNegative ? 'in $hours hr' : '$hours hr ago';
    }
    if (delta.inDays.abs() < 7) {
      final int days = delta.inDays.abs();
      return delta.isNegative ? 'in $days d' : '$days d ago';
    }
    return date(value, locale: locale);
  }
}
