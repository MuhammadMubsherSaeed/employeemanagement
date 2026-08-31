import 'package:equatable/equatable.dart';
import 'package:flutter_base/core/constants/app_constants.dart';
import 'package:flutter_base/features/devices/domain/entities/device.dart';
import 'package:flutter_base/features/devices/domain/entities/device_enums.dart';

class DeviceQuery extends Equatable {
  const DeviceQuery({
    this.search = '',
    this.status,
    this.type,
    this.manufacturer,
    this.assigned,
    this.employeeId,
    this.ordering = 'asset_code',
    this.page = 1,
    this.pageSize = AppConstants.defaultPageSize,
  });

  final String search;
  final DeviceStatus? status;
  final String? type;
  final String? manufacturer;
  final bool? assigned;
  final String? employeeId;
  final String ordering;
  final int page;
  final int pageSize;

  int get activeFilterCount {
    int count = 0;
    if (status != null) {
      count++;
    }
    if (type != null && type!.trim().isNotEmpty) {
      count++;
    }
    if (manufacturer != null && manufacturer!.trim().isNotEmpty) {
      count++;
    }
    if (assigned != null) {
      count++;
    }
    if (employeeId != null) {
      count++;
    }
    return count;
  }

  DeviceQuery copyWith({
    String? search,
    DeviceStatus? status,
    String? type,
    String? manufacturer,
    bool? assigned,
    String? employeeId,
    String? ordering,
    int? page,
    int? pageSize,
    bool clearStatus = false,
    bool clearType = false,
    bool clearManufacturer = false,
    bool clearAssigned = false,
    bool clearEmployee = false,
  }) {
    return DeviceQuery(
      search: search ?? this.search,
      status: clearStatus ? null : (status ?? this.status),
      type: clearType ? null : (type ?? this.type),
      manufacturer:
          clearManufacturer ? null : (manufacturer ?? this.manufacturer),
      assigned: clearAssigned ? null : (assigned ?? this.assigned),
      employeeId: clearEmployee ? null : (employeeId ?? this.employeeId),
      ordering: ordering ?? this.ordering,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  DeviceQuery clearedFilters() {
    return DeviceQuery(
      search: search,
      ordering: ordering,
      page: 1,
      pageSize: pageSize,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    return <String, dynamic>{
      if (search.trim().isNotEmpty) 'search': search.trim(),
      if (status != null && status != DeviceStatus.unknown)
        'status': status!.apiValue,
      if (type != null && type!.trim().isNotEmpty) 'type': type!.trim(),
      if (manufacturer != null && manufacturer!.trim().isNotEmpty)
        'manufacturer': manufacturer!.trim(),
      if (assigned != null) 'assigned': assigned,
      if (employeeId != null) 'employee': employeeId,
      'ordering': ordering,
      'page': page,
      'page_size': pageSize,
    };
  }

  @override
  List<Object?> get props => <Object?>[
        search,
        status,
        type,
        manufacturer,
        assigned,
        employeeId,
        ordering,
        page,
        pageSize,
      ];
}

class DeviceHistoryQuery extends Equatable {
  const DeviceHistoryQuery({
    this.page = 1,
    this.pageSize = AppConstants.defaultPageSize,
  });

  final int page;
  final int pageSize;

  DeviceHistoryQuery copyWith({int? page, int? pageSize}) {
    return DeviceHistoryQuery(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    return <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
  }

  @override
  List<Object?> get props => <Object?>[page, pageSize];
}

class DevicePage<T> extends Equatable {
  const DevicePage({
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

class DeviceWrite extends Equatable {
  const DeviceWrite({
    required this.assetCode,
    required this.type,
    this.manufacturer = '',
    this.model = '',
    this.serialNumber,
    this.purchaseDate,
    this.warrantyExpiry,
    this.cost,
    this.notes = '',
    this.status,
  });

  final String assetCode;
  final String type;
  final String manufacturer;
  final String model;
  final String? serialNumber;
  final DateTime? purchaseDate;
  final DateTime? warrantyExpiry;
  final String? cost;
  final String notes;
  final DeviceStatus? status;

  factory DeviceWrite.fromDevice(Device device) {
    return DeviceWrite(
      assetCode: device.assetCode,
      type: device.type,
      manufacturer: device.manufacturer,
      model: device.model,
      serialNumber: device.serialNumber,
      purchaseDate: device.purchaseDate,
      warrantyExpiry: device.warrantyExpiry,
      cost: device.cost,
      notes: device.notes ?? '',
      status: device.status,
    );
  }

  Map<String, dynamic> toJson({bool includeStatus = false}) {
    return <String, dynamic>{
      'asset_code': assetCode.trim().toUpperCase(),
      'type': type.trim(),
      'manufacturer': manufacturer.trim(),
      'model': model.trim(),
      if (serialNumber != null && serialNumber!.trim().isNotEmpty)
        'serial_number': serialNumber!.trim(),
      if (purchaseDate != null) 'purchase_date': formatDeviceDateParam(purchaseDate!),
      if (warrantyExpiry != null)
        'warranty_expiry': formatDeviceDateParam(warrantyExpiry!),
      if (cost != null && cost!.trim().isNotEmpty) 'cost': cost!.trim(),
      'notes': notes.trim(),
      if (includeStatus &&
          status != null &&
          status != DeviceStatus.unknown &&
          status != DeviceStatus.assigned)
        'status': status!.apiValue,
    };
  }

  @override
  List<Object?> get props => <Object?>[
        assetCode,
        type,
        manufacturer,
        model,
        serialNumber,
        purchaseDate,
        warrantyExpiry,
        cost,
        notes,
        status,
      ];
}

class AssignDeviceBody extends Equatable {
  const AssignDeviceBody({
    required this.employeeId,
    this.conditionOnAssignment = '',
    this.notes = '',
  });

  final String employeeId;
  final String conditionOnAssignment;
  final String notes;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'employee_id': employeeId,
      if (conditionOnAssignment.trim().isNotEmpty)
        'condition_on_assignment': conditionOnAssignment.trim(),
      if (notes.trim().isNotEmpty) 'notes': notes.trim(),
    };
  }

  @override
  List<Object?> get props => <Object?>[employeeId, conditionOnAssignment, notes];
}

class ReturnDeviceBody extends Equatable {
  const ReturnDeviceBody({
    this.conditionOnReturn = '',
    this.notes = '',
  });

  final String conditionOnReturn;
  final String notes;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (conditionOnReturn.trim().isNotEmpty)
        'condition_on_return': conditionOnReturn.trim(),
      if (notes.trim().isNotEmpty) 'notes': notes.trim(),
    };
  }

  @override
  List<Object?> get props => <Object?>[conditionOnReturn, notes];
}

String formatDeviceDateParam(DateTime value) {
  final DateTime local = DateTime(value.year, value.month, value.day);
  final String month = local.month.toString().padLeft(2, '0');
  final String day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}
