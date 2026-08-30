import 'package:intl/intl.dart';

class AppDateFormatter {
  AppDateFormatter._();

  static String date(DateTime value, {String? locale}) {
    return DateFormat.yMMMd(locale).format(value);
  }

  static String dateTime(DateTime value, {String? locale}) {
    return DateFormat.yMMMd(locale).add_jm().format(value);
  }
}
