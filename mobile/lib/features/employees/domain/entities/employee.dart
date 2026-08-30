import 'package:equatable/equatable.dart';
import 'package:flutter_base/features/employees/domain/entities/employee_enums.dart';

class EmployeeUserRef extends Equatable {
  const EmployeeUserRef({
    required this.id,
    required this.email,
  });

  final int id;
  final String email;

  factory EmployeeUserRef.fromJson(Map<String, dynamic> json) {
    return EmployeeUserRef(
      id: _readInt(json['id']),
      email: _readString(json['email']),
    );
  }

  @override
  List<Object?> get props => <Object?>[id, email];
}

class EmployeeManagerRef extends Equatable {
  const EmployeeManagerRef({
    required this.id,
    required this.employeeCode,
    required this.firstName,
    required this.lastName,
  });

  final String id;
  final String employeeCode;
  final String firstName;
  final String lastName;

  String get fullName => '$firstName $lastName'.trim();

  factory EmployeeManagerRef.fromJson(Map<String, dynamic> json) {
    return EmployeeManagerRef(
      id: _readString(json['id']),
      employeeCode: _readString(json['employee_code']),
      firstName: _readString(json['first_name']),
      lastName: _readString(json['last_name']),
    );
  }

  @override
  List<Object?> get props => <Object?>[id, employeeCode, firstName, lastName];
}

class Department extends Equatable {
  const Department({
    required this.id,
    required this.name,
    required this.status,
    this.description = '',
    this.managerId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final OrgStatus status;
  final String description;
  final String? managerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: _readString(json['id']),
      name: _readString(json['name']),
      status: OrgStatus.fromApi(_readString(json['status'])),
      description: _readString(json['description']),
      managerId: _readOptionalId(json['manager']),
      createdAt: _readDate(json['created_at']),
      updatedAt: _readDate(json['updated_at']),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        name,
        status,
        description,
        managerId,
        createdAt,
        updatedAt,
      ];
}

class Position extends Equatable {
  const Position({
    required this.id,
    required this.title,
    required this.status,
    this.departmentId,
    this.description = '',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final OrgStatus status;
  final String? departmentId;
  final String description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      id: _readString(json['id']),
      title: _readString(json['title']),
      status: OrgStatus.fromApi(_readString(json['status'])),
      departmentId: _readOptionalId(json['department']),
      description: _readString(json['description']),
      createdAt: _readDate(json['created_at']),
      updatedAt: _readDate(json['updated_at']),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        title,
        status,
        departmentId,
        description,
        createdAt,
        updatedAt,
      ];
}

class Employee extends Equatable {
  const Employee({
    required this.id,
    required this.employeeCode,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.employmentType,
    required this.status,
    this.profileImage = '',
    this.gender = EmployeeGender.unknown,
    this.dateOfBirth,
    this.phone = '',
    this.address = '',
    this.emergencyContactName = '',
    this.emergencyContactRelationship = '',
    this.emergencyContactPhone = '',
    this.department,
    this.position,
    this.manager,
    this.user,
    this.joiningDate,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String employeeCode;
  final String firstName;
  final String lastName;
  final String fullName;
  final EmploymentType employmentType;
  final EmployeeStatus status;
  final String profileImage;
  final EmployeeGender gender;
  final DateTime? dateOfBirth;
  final String phone;
  final String address;
  final String emergencyContactName;
  final String emergencyContactRelationship;
  final String emergencyContactPhone;
  final Department? department;
  final Position? position;
  final EmployeeManagerRef? manager;
  final EmployeeUserRef? user;
  final DateTime? joiningDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasPrivateContact =>
      phone.isNotEmpty ||
      address.isNotEmpty ||
      emergencyContactName.isNotEmpty ||
      dateOfBirth != null;

  Employee copyWith({
    String? id,
    String? employeeCode,
    String? firstName,
    String? lastName,
    String? fullName,
    EmploymentType? employmentType,
    EmployeeStatus? status,
    String? profileImage,
    EmployeeGender? gender,
    DateTime? dateOfBirth,
    String? phone,
    String? address,
    String? emergencyContactName,
    String? emergencyContactRelationship,
    String? emergencyContactPhone,
    Department? department,
    Position? position,
    EmployeeManagerRef? manager,
    EmployeeUserRef? user,
    DateTime? joiningDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Employee(
      id: id ?? this.id,
      employeeCode: employeeCode ?? this.employeeCode,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      fullName: fullName ?? this.fullName,
      employmentType: employmentType ?? this.employmentType,
      status: status ?? this.status,
      profileImage: profileImage ?? this.profileImage,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactRelationship:
          emergencyContactRelationship ?? this.emergencyContactRelationship,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      department: department ?? this.department,
      position: position ?? this.position,
      manager: manager ?? this.manager,
      user: user ?? this.user,
      joiningDate: joiningDate ?? this.joiningDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Employee.fromJson(Map<String, dynamic> json) {
    final String first = _readString(json['first_name']);
    final String last = _readString(json['last_name']);
    final String full = _readString(json['full_name']);
    return Employee(
      id: _readString(json['id']),
      employeeCode: _readString(json['employee_code']),
      firstName: first,
      lastName: last,
      fullName: full.isNotEmpty ? full : '$first $last'.trim(),
      profileImage: _readString(json['profile_image']),
      gender: EmployeeGender.fromApi(_readString(json['gender'])),
      dateOfBirth: _readDate(json['date_of_birth']),
      phone: _readString(json['phone']),
      address: _readString(json['address']),
      emergencyContactName: _readString(json['emergency_contact_name']),
      emergencyContactRelationship: _readString(
        json['emergency_contact_relationship'],
      ),
      emergencyContactPhone: _readString(json['emergency_contact_phone']),
      department: _readDepartment(json['department']),
      position: _readPosition(json['position']),
      manager: _readManager(json['manager']),
      user: _readUser(json['user']),
      joiningDate: _readDate(json['joining_date']),
      employmentType: EmploymentType.fromApi(
        _readString(json['employment_type']),
      ),
      status: EmployeeStatus.fromApi(_readString(json['status'])),
      createdAt: _readDate(json['created_at']),
      updatedAt: _readDate(json['updated_at']),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        employeeCode,
        firstName,
        lastName,
        fullName,
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
        department,
        position,
        manager,
        user,
        joiningDate,
        createdAt,
        updatedAt,
      ];
}

Department? _readDepartment(dynamic value) {
  if (value is Map) {
    return Department.fromJson(Map<String, dynamic>.from(value));
  }
  return null;
}

Position? _readPosition(dynamic value) {
  if (value is Map) {
    return Position.fromJson(Map<String, dynamic>.from(value));
  }
  return null;
}

EmployeeManagerRef? _readManager(dynamic value) {
  if (value is Map) {
    return EmployeeManagerRef.fromJson(Map<String, dynamic>.from(value));
  }
  return null;
}

EmployeeUserRef? _readUser(dynamic value) {
  if (value is Map) {
    return EmployeeUserRef.fromJson(Map<String, dynamic>.from(value));
  }
  return null;
}

String _readString(dynamic value) {
  if (value == null) {
    return '';
  }
  return value.toString();
}

int _readInt(dynamic value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String? _readOptionalId(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is Map) {
    final String id = _readString(value['id']);
    return id.isEmpty ? null : id;
  }
  final String id = value.toString();
  return id.isEmpty ? null : id;
}

DateTime? _readDate(dynamic value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value.toString());
}
