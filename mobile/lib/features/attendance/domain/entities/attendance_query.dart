import 'package:equatable/equatable.dart';
import 'package:flutter_base/core/constants/app_constants.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance_enums.dart';

class AttendanceQuery extends Equatable {
  const AttendanceQuery({
    this.startDate,
    this.endDate,
    this.status,
    this.employeeId,
    this.departmentId,
    this.ordering = '-date',
    this.page = 1,
    this.pageSize = AppConstants.defaultPageSize,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final AttendanceStatus? status;
  final String? employeeId;
  final String? departmentId;
  final String ordering;
  final int page;
  final int pageSize;

  int get activeFilterCount {
    int count = 0;
    if (startDate != null) {
      count++;
    }
    if (endDate != null) {
      count++;
    }
    if (status != null) {
      count++;
    }
    if (employeeId != null) {
      count++;
    }
    if (departmentId != null) {
      count++;
    }
    return count;
  }

  AttendanceQuery copyWith({
    DateTime? startDate,
    DateTime? endDate,
    AttendanceStatus? status,
    String? employeeId,
    String? departmentId,
    String? ordering,
    int? page,
    int? pageSize,
    bool clearStart = false,
    bool clearEnd = false,
    bool clearStatus = false,
    bool clearEmployee = false,
    bool clearDepartment = false,
  }) {
    return AttendanceQuery(
      startDate: clearStart ? null : (startDate ?? this.startDate),
      endDate: clearEnd ? null : (endDate ?? this.endDate),
      status: clearStatus ? null : (status ?? this.status),
      employeeId: clearEmployee ? null : (employeeId ?? this.employeeId),
      departmentId:
          clearDepartment ? null : (departmentId ?? this.departmentId),
      ordering: ordering ?? this.ordering,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  AttendanceQuery clearedFilters() {
    return AttendanceQuery(
      ordering: ordering,
      page: 1,
      pageSize: pageSize,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    return <String, dynamic>{
      if (startDate != null) 'start_date': formatDateParam(startDate!),
      if (endDate != null) 'end_date': formatDateParam(endDate!),
      if (status != null && status != AttendanceStatus.unknown)
        'status': status!.apiValue,
      if (employeeId != null) 'employee': employeeId,
      if (departmentId != null) 'department': departmentId,
      'ordering': ordering,
      'page': page,
      'page_size': pageSize,
    };
  }

  @override
  List<Object?> get props => <Object?>[
        startDate,
        endDate,
        status,
        employeeId,
        departmentId,
        ordering,
        page,
        pageSize,
      ];
}

class AttendancePage<T> extends Equatable {
  const AttendancePage({
    required this.results,
    required this.count,
    this.next,
    this.previous,
  });

  final List<T> results;
  final int count;
  final String? next;
  final String? previous;

  bool get hasMore => next != null && next!.trim().isNotEmpty;

  @override
  List<Object?> get props => <Object?>[results, count, next, previous];
}

class AttendanceSummaryQuery extends Equatable {
  const AttendanceSummaryQuery({
    required this.startDate,
    required this.endDate,
    this.employeeId,
  });

  final DateTime startDate;
  final DateTime endDate;
  final String? employeeId;

  Map<String, dynamic> toQueryParameters() {
    return <String, dynamic>{
      'start_date': formatDateParam(startDate),
      'end_date': formatDateParam(endDate),
      if (employeeId != null) 'employee_id': employeeId,
    };
  }

  @override
  List<Object?> get props => <Object?>[startDate, endDate, employeeId];
}

class CheckInOutBody extends Equatable {
  const CheckInOutBody({this.latitude, this.longitude});

  final double? latitude;
  final double? longitude;

  Map<String, dynamic> toJson() {
    if (latitude == null || longitude == null) {
      return const <String, dynamic>{};
    }
    return <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  @override
  List<Object?> get props => <Object?>[latitude, longitude];
}

String formatDateParam(DateTime value) {
  final DateTime local = DateTime(value.year, value.month, value.day);
  final String month = local.month.toString().padLeft(2, '0');
  final String day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

DateTime monthStart(DateTime month) => DateTime(month.year, month.month, 1);

DateTime monthEnd(DateTime month) => DateTime(month.year, month.month + 1, 0);

AttendancePage<AttendanceRecord> emptyAttendancePage() {
  return const AttendancePage<AttendanceRecord>(results: <AttendanceRecord>[], count: 0);
}
