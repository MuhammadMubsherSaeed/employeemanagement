import 'package:equatable/equatable.dart';
import 'package:flutter_base/features/devices/domain/entities/device_enums.dart';

class DeviceEmployeeRef extends Equatable {
  const DeviceEmployeeRef({
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

  factory DeviceEmployeeRef.fromJson(Map<String, dynamic> json) {
    return DeviceEmployeeRef(
      id: _readString(json['id']),
      employeeCode: _readString(json['employee_code']),
      firstName: _readString(json['first_name']),
      lastName: _readString(json['last_name']),
    );
  }

  @override
  List<Object?> get props => <Object?>[id, employeeCode, firstName, lastName];
}

class Device extends Equatable {
  const Device({
    required this.id,
    required this.assetCode,
    required this.type,
    required this.status,
    this.manufacturer = '',
    this.model = '',
    this.serialNumber,
    this.purchaseDate,
    this.warrantyExpiry,
    this.cost,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String assetCode;
  final String type;
  final String manufacturer;
  final String model;
  final String? serialNumber;
  final DateTime? purchaseDate;
  final DateTime? warrantyExpiry;
  final String? cost;
  final DeviceStatus status;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasCost => cost != null;

  bool get hasNotes => notes != null;

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: _readString(json['id']),
      assetCode: _readString(json['asset_code']),
      type: _readString(json['type']),
      manufacturer: _readString(json['manufacturer']),
      model: _readString(json['model']),
      serialNumber: _readOptionalString(json['serial_number']),
      purchaseDate: _readDate(json['purchase_date']),
      warrantyExpiry: _readDate(json['warranty_expiry']),
      cost: json.containsKey('cost') ? _readOptionalString(json['cost']) : null,
      status: DeviceStatus.fromApi(_readString(json['status'])),
      notes: json.containsKey('notes') ? _readOptionalString(json['notes']) : null,
      createdAt: _readDateTime(json['created_at']),
      updatedAt: _readDateTime(json['updated_at']),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        assetCode,
        type,
        manufacturer,
        model,
        serialNumber,
        purchaseDate,
        warrantyExpiry,
        cost,
        status,
        notes,
        createdAt,
        updatedAt,
      ];
}

class DeviceHistoryItem extends Equatable {
  const DeviceHistoryItem({
    required this.id,
    required this.assignedAt,
    this.employee,
    this.returnedAt,
    this.conditionOnAssignment = '',
    this.conditionOnReturn = '',
    this.notes = '',
    this.createdAt,
  });

  final String id;
  final DeviceEmployeeRef? employee;
  final DateTime assignedAt;
  final DateTime? returnedAt;
  final String conditionOnAssignment;
  final String conditionOnReturn;
  final String notes;
  final DateTime? createdAt;

  bool get isActive => returnedAt == null;

  factory DeviceHistoryItem.fromJson(Map<String, dynamic> json) {
    return DeviceHistoryItem(
      id: _readString(json['id']),
      employee: _readEmployee(json['employee']),
      assignedAt: _readDateTime(json['assigned_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      returnedAt: _readDateTime(json['returned_at']),
      conditionOnAssignment: _readString(json['condition_on_assignment']),
      conditionOnReturn: _readString(json['condition_on_return']),
      notes: _readString(json['notes']),
      createdAt: _readDateTime(json['created_at']),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        employee,
        assignedAt,
        returnedAt,
        conditionOnAssignment,
        conditionOnReturn,
        notes,
        createdAt,
      ];
}

DeviceEmployeeRef? _readEmployee(dynamic value) {
  if (value is Map) {
    return DeviceEmployeeRef.fromJson(Map<String, dynamic>.from(value));
  }
  return null;
}

String _readString(dynamic value) {
  if (value == null) {
    return '';
  }
  return value.toString();
}

String? _readOptionalString(dynamic value) {
  if (value == null) {
    return null;
  }
  final String text = value.toString().trim();
  return text.isEmpty ? null : text;
}

DateTime? _readDate(dynamic value) {
  if (value == null) {
    return null;
  }
  final String raw = value.toString();
  final DateTime? parsed = raw.length >= 10
      ? DateTime.tryParse(raw.substring(0, 10))
      : DateTime.tryParse(raw);
  if (parsed == null) {
    return null;
  }
  return DateTime(parsed.year, parsed.month, parsed.day);
}

DateTime? _readDateTime(dynamic value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value.toString());
}
