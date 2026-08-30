import 'package:flutter_base/core/utils/date_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats date, time, and relative values', () {
    final DateTime value = DateTime(2026, 8, 30, 14, 30);
    expect(AppDateFormatter.date(value), contains('2026'));
    expect(AppDateFormatter.time(value), isNotEmpty);
    expect(AppDateFormatter.dateTime(value), contains('2026'));
    expect(
      AppDateFormatter.relative(
        value.subtract(const Duration(minutes: 5)),
        now: value,
      ),
      '5 min ago',
    );
  });
}
