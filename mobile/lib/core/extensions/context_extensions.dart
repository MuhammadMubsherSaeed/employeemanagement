import 'package:flutter/material.dart';
import 'package:flutter_base/core/utils/date_formatter.dart';
import 'package:flutter_base/l10n/app_localizations.dart';

extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);

  ColorScheme get colors => Theme.of(this).colorScheme;

  TextTheme get textTheme => Theme.of(this).textTheme;

  AppLocalizations? get l10n => AppLocalizations.of(this);

  MediaQueryData get mediaQuery => MediaQuery.of(this);

  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  void showSnack(String message) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

extension StringX on String {
  String get initials {
    final List<String> parts =
        trim().split(RegExp(r'\s+')).where((String p) => p.isNotEmpty).toList();
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  bool get isBlank => trim().isEmpty;
}

extension DateTimeX on DateTime {
  String toAppDate({String? locale}) =>
      AppDateFormatter.date(this, locale: locale);

  String toAppDateTime({String? locale}) =>
      AppDateFormatter.dateTime(this, locale: locale);
}
