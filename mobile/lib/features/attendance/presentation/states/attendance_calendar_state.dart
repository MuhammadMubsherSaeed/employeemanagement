import 'package:equatable/equatable.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance_query.dart';

class AttendanceCalendarState extends Equatable {
  const AttendanceCalendarState({
    required this.month,
    this.records = const <AttendanceRecord>[],
    this.isLoading = false,
    this.error,
  });

  final DateTime month;
  final List<AttendanceRecord> records;
  final bool isLoading;
  final String? error;

  Map<String, AttendanceRecord> get byDate {
    final Map<String, AttendanceRecord> mapped = <String, AttendanceRecord>{};
    for (final AttendanceRecord record in records) {
      mapped[formatDateParam(record.date)] = record;
    }
    return mapped;
  }

  AttendanceCalendarState copyWith({
    DateTime? month,
    List<AttendanceRecord>? records,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AttendanceCalendarState(
      month: month ?? this.month,
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => <Object?>[month, records, isLoading, error];
}
