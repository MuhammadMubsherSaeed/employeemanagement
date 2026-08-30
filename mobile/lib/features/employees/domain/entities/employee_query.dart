import 'package:equatable/equatable.dart';
import 'package:flutter_base/core/constants/app_constants.dart';
import 'package:flutter_base/features/employees/domain/entities/employee_enums.dart';

class EmployeeQuery extends Equatable {
  const EmployeeQuery({
    this.search = '',
    this.departmentId,
    this.positionId,
    this.status,
    this.employmentType,
    this.managerId,
    this.ordering = '-created_at',
    this.page = 1,
    this.pageSize = AppConstants.defaultPageSize,
  });

  final String search;
  final String? departmentId;
  final String? positionId;
  final EmployeeStatus? status;
  final EmploymentType? employmentType;
  final String? managerId;
  final String ordering;
  final int page;
  final int pageSize;

  int get activeFilterCount {
    int count = 0;
    if (departmentId != null) {
      count++;
    }
    if (positionId != null) {
      count++;
    }
    if (status != null) {
      count++;
    }
    if (employmentType != null) {
      count++;
    }
    if (managerId != null) {
      count++;
    }
    return count;
  }

  EmployeeQuery copyWith({
    String? search,
    String? departmentId,
    String? positionId,
    EmployeeStatus? status,
    EmploymentType? employmentType,
    String? managerId,
    String? ordering,
    int? page,
    int? pageSize,
    bool clearDepartment = false,
    bool clearPosition = false,
    bool clearStatus = false,
    bool clearEmploymentType = false,
    bool clearManager = false,
  }) {
    return EmployeeQuery(
      search: search ?? this.search,
      departmentId: clearDepartment ? null : (departmentId ?? this.departmentId),
      positionId: clearPosition ? null : (positionId ?? this.positionId),
      status: clearStatus ? null : (status ?? this.status),
      employmentType: clearEmploymentType
          ? null
          : (employmentType ?? this.employmentType),
      managerId: clearManager ? null : (managerId ?? this.managerId),
      ordering: ordering ?? this.ordering,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  EmployeeQuery clearedFilters() {
    return EmployeeQuery(
      search: search,
      ordering: ordering,
      page: 1,
      pageSize: pageSize,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    return <String, dynamic>{
      if (search.trim().isNotEmpty) 'search': search.trim(),
      if (departmentId != null) 'department': departmentId,
      if (positionId != null) 'position': positionId,
      if (status != null) 'status': status!.apiValue,
      if (employmentType != null) 'employment_type': employmentType!.apiValue,
      if (managerId != null) 'manager': managerId,
      'ordering': ordering,
      'page': page,
      'page_size': pageSize,
    };
  }

  @override
  List<Object?> get props => <Object?>[
        search,
        departmentId,
        positionId,
        status,
        employmentType,
        managerId,
        ordering,
        page,
        pageSize,
      ];
}

class EmployeePage<T> extends Equatable {
  const EmployeePage({
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

class EmployeeWrite extends Equatable {
  const EmployeeWrite({
    required this.employeeCode,
    required this.firstName,
    required this.lastName,
    required this.employmentType,
    required this.status,
    this.profileImage,
    this.gender,
    this.dateOfBirth,
    this.phone,
    this.address,
    this.emergencyContactName,
    this.emergencyContactRelationship,
    this.emergencyContactPhone,
    this.userId,
    this.departmentId,
    this.positionId,
    this.managerId,
    this.joiningDate,
  });

  final String employeeCode;
  final String firstName;
  final String lastName;
  final EmploymentType employmentType;
  final EmployeeStatus status;
  final String? profileImage;
  final EmployeeGender? gender;
  final DateTime? dateOfBirth;
  final String? phone;
  final String? address;
  final String? emergencyContactName;
  final String? emergencyContactRelationship;
  final String? emergencyContactPhone;
  final int? userId;
  final String? departmentId;
  final String? positionId;
  final String? managerId;
  final DateTime? joiningDate;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'employee_code': employeeCode,
      'first_name': firstName,
      'last_name': lastName,
      'employment_type': employmentType.apiValue,
      'status': status.apiValue,
      if (profileImage != null) 'profile_image': profileImage,
      if (gender != null && gender != EmployeeGender.unknown)
        'gender': gender!.apiValue,
      if (dateOfBirth != null)
        'date_of_birth': _dateOnly(dateOfBirth!),
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (emergencyContactName != null)
        'emergency_contact_name': emergencyContactName,
      if (emergencyContactRelationship != null)
        'emergency_contact_relationship': emergencyContactRelationship,
      if (emergencyContactPhone != null)
        'emergency_contact_phone': emergencyContactPhone,
      if (userId != null) 'user': userId,
      'department': departmentId,
      'position': positionId,
      'manager': managerId,
      if (joiningDate != null) 'joining_date': _dateOnly(joiningDate!),
    };
  }

  static String _dateOnly(DateTime value) {
    final DateTime local = DateTime(value.year, value.month, value.day);
    final String month = local.month.toString().padLeft(2, '0');
    final String day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  @override
  List<Object?> get props => <Object?>[
        employeeCode,
        firstName,
        lastName,
        employmentType,
        status,
        profileImage,
        gender,
        dateOfBirth,
        phone,
        address,
        emergencyContactName,
        emergencyContactRelationship,
        emergencyContactPhone,
        userId,
        departmentId,
        positionId,
        managerId,
        joiningDate,
      ];
}
