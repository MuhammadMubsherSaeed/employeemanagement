import 'package:equatable/equatable.dart';
import 'package:flutter_base/core/constants/app_constants.dart';
import 'package:flutter_base/features/reports/domain/entities/report_json.dart';
import 'package:flutter_base/features/reports/domain/entities/report_kind.dart';

class ReportQuery extends Equatable {
  const ReportQuery({
    required this.kind,
    this.dateFrom,
    this.dateTo,
    this.employeeId,
    this.departmentId,
    this.status,
    this.leaveTypeId,
    this.employmentType,
    this.search = '',
    this.page = 1,
    this.pageSize = AppConstants.defaultPageSize,
  });

  final ReportKind kind;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? employeeId;
  final String? departmentId;
  final String? status;
  final String? leaveTypeId;
  final String? employmentType;
  final String search;
  final int page;
  final int pageSize;

  bool get hasInvalidDateRange {
    if (!kind.supportsDates || dateFrom == null || dateTo == null) {
      return false;
    }
    return formatReportDateParam(dateFrom!)
            .compareTo(formatReportDateParam(dateTo!)) >
        0;
  }

  int get activeFilterCount {
    int count = 0;
    if (kind.supportsDates) {
      if (dateFrom != null) {
        count++;
      }
      if (dateTo != null) {
        count++;
      }
    }
    if (employeeId != null && employeeId!.isNotEmpty) {
      count++;
    }
    if (departmentId != null && departmentId!.isNotEmpty) {
      count++;
    }
    if (status != null && status!.isNotEmpty) {
      count++;
    }
    if (kind.supportsLeaveType &&
        leaveTypeId != null &&
        leaveTypeId!.isNotEmpty) {
      count++;
    }
    if (kind.supportsEmploymentType &&
        employmentType != null &&
        employmentType!.isNotEmpty) {
      count++;
    }
    return count;
  }

  ReportQuery copyWith({
    DateTime? dateFrom,
    DateTime? dateTo,
    String? employeeId,
    String? departmentId,
    String? status,
    String? leaveTypeId,
    String? employmentType,
    String? search,
    int? page,
    int? pageSize,
    bool clearDateFrom = false,
    bool clearDateTo = false,
    bool clearEmployee = false,
    bool clearDepartment = false,
    bool clearStatus = false,
    bool clearLeaveType = false,
    bool clearEmploymentType = false,
  }) {
    return ReportQuery(
      kind: kind,
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
      employeeId: clearEmployee ? null : (employeeId ?? this.employeeId),
      departmentId:
          clearDepartment ? null : (departmentId ?? this.departmentId),
      status: clearStatus ? null : (status ?? this.status),
      leaveTypeId: clearLeaveType ? null : (leaveTypeId ?? this.leaveTypeId),
      employmentType: clearEmploymentType
          ? null
          : (employmentType ?? this.employmentType),
      search: search ?? this.search,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  ReportQuery clearedFilters() {
    return ReportQuery(
      kind: kind,
      search: search,
      page: 1,
      pageSize: pageSize,
    );
  }

  ReportQuery sanitized() {
    return ReportQuery(
      kind: kind,
      dateFrom: kind.supportsDates ? dateFrom : null,
      dateTo: kind.supportsDates ? dateTo : null,
      employeeId: employeeId,
      departmentId: departmentId,
      status: status,
      leaveTypeId: kind.supportsLeaveType ? leaveTypeId : null,
      employmentType: kind.supportsEmploymentType ? employmentType : null,
      search: search,
      page: page,
      pageSize: pageSize,
    );
  }

  Map<String, dynamic> toQueryParameters({bool includePagination = true}) {
    final ReportQuery query = sanitized();
    return <String, dynamic>{
      if (query.kind.supportsDates && query.dateFrom != null)
        'date_from': formatReportDateParam(query.dateFrom!),
      if (query.kind.supportsDates && query.dateTo != null)
        'date_to': formatReportDateParam(query.dateTo!),
      if (query.employeeId != null && query.employeeId!.isNotEmpty)
        'employee': query.employeeId,
      if (query.departmentId != null && query.departmentId!.isNotEmpty)
        'department': query.departmentId,
      if (query.status != null && query.status!.isNotEmpty)
        'status': query.status,
      if (query.kind.supportsLeaveType &&
          query.leaveTypeId != null &&
          query.leaveTypeId!.isNotEmpty)
        'leave_type': query.leaveTypeId,
      if (query.kind.supportsEmploymentType &&
          query.employmentType != null &&
          query.employmentType!.isNotEmpty)
        'employment_type': query.employmentType,
      if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
      if (includePagination) 'page': query.page,
      if (includePagination) 'page_size': query.pageSize,
    };
  }

  bool matchesListQuery(ReportQuery other) {
    return kind == other.kind &&
        _sameDay(dateFrom, other.dateFrom) &&
        _sameDay(dateTo, other.dateTo) &&
        employeeId == other.employeeId &&
        departmentId == other.departmentId &&
        status == other.status &&
        leaveTypeId == other.leaveTypeId &&
        employmentType == other.employmentType &&
        search == other.search &&
        pageSize == other.pageSize;
  }

  static bool _sameDay(DateTime? a, DateTime? b) {
    if (a == null && b == null) {
      return true;
    }
    if (a == null || b == null) {
      return false;
    }
    return formatReportDateParam(a) == formatReportDateParam(b);
  }

  @override
  List<Object?> get props => <Object?>[
        kind,
        dateFrom,
        dateTo,
        employeeId,
        departmentId,
        status,
        leaveTypeId,
        employmentType,
        search,
        page,
        pageSize,
      ];
}

class ReportPage<T> extends Equatable {
  const ReportPage({
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
