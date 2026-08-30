import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/core/network/api_client.dart';
import 'package:flutter_base/core/network/models/api_envelope.dart';
import 'package:flutter_base/features/employees/data/employee_endpoints.dart';
import 'package:flutter_base/features/employees/domain/entities/employee.dart';
import 'package:flutter_base/features/employees/domain/entities/employee_query.dart';

abstract class EmployeeRemoteDataSource {
  Future<EmployeePage<Employee>> getEmployees(EmployeeQuery query);

  Future<Employee> getEmployeeById(String id);

  Future<Employee> getMyEmployeeProfile();

  Future<Employee> createEmployee(EmployeeWrite body);

  Future<Employee> updateEmployee(String id, EmployeeWrite body);

  Future<void> deleteEmployee(String id);

  Future<List<Department>> getDepartments({String? status});

  Future<List<Position>> getPositions({String? departmentId, String? status});
}

class EmployeeRemoteDataSourceImpl implements EmployeeRemoteDataSource {
  EmployeeRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<EmployeePage<Employee>> getEmployees(EmployeeQuery query) async {
    final response = await _client.get<dynamic>(
      EmployeeEndpoints.employees,
      queryParameters: query.toQueryParameters(),
    );
    return _page(response.data, Employee.fromJson);
  }

  @override
  Future<Employee> getEmployeeById(String id) async {
    final response = await _client.get<dynamic>(EmployeeEndpoints.employee(id));
    return Employee.fromJson(_data(_envelope(response.data)));
  }

  @override
  Future<Employee> getMyEmployeeProfile() async {
    final response = await _client.get<dynamic>(EmployeeEndpoints.me);
    return Employee.fromJson(_data(_envelope(response.data)));
  }

  @override
  Future<Employee> createEmployee(EmployeeWrite body) async {
    final response = await _client.post<dynamic>(
      EmployeeEndpoints.employees,
      data: body.toJson(),
    );
    return Employee.fromJson(_data(_envelope(response.data)));
  }

  @override
  Future<Employee> updateEmployee(String id, EmployeeWrite body) async {
    final response = await _client.patch<dynamic>(
      EmployeeEndpoints.employee(id),
      data: body.toJson(),
    );
    return Employee.fromJson(_data(_envelope(response.data)));
  }

  @override
  Future<void> deleteEmployee(String id) async {
    await _client.delete<dynamic>(EmployeeEndpoints.employee(id));
  }

  @override
  Future<List<Department>> getDepartments({String? status}) async {
    final response = await _client.get<dynamic>(
      EmployeeEndpoints.departments,
      queryParameters: <String, dynamic>{
        'page_size': 100,
        if (status != null) 'status': status,
      },
    );
    return _list(response.data, Department.fromJson);
  }

  @override
  Future<List<Position>> getPositions({
    String? departmentId,
    String? status,
  }) async {
    final response = await _client.get<dynamic>(
      EmployeeEndpoints.positions,
      queryParameters: <String, dynamic>{
        'page_size': 100,
        if (departmentId != null) 'department': departmentId,
        if (status != null) 'status': status,
      },
    );
    return _list(response.data, Position.fromJson);
  }

  EmployeePage<T> _page<T>(
    dynamic raw,
    T Function(Map<String, dynamic> json) parse,
  ) {
    final Map<String, dynamic> data = _data(_envelope(raw));
    final Object? results = data['results'];
    final List<T> items = <T>[];
    if (results is List) {
      for (final Object? row in results) {
        if (row is Map) {
          items.add(parse(Map<String, dynamic>.from(row)));
        }
      }
    }
    return EmployeePage<T>(
      results: items,
      count: _readInt(data['count'], fallback: items.length),
      next: data['next']?.toString(),
      previous: data['previous']?.toString(),
    );
  }

  List<T> _list<T>(
    dynamic raw,
    T Function(Map<String, dynamic> json) parse,
  ) {
    final ApiEnvelope envelope = _envelope(raw);
    final Object? data = envelope.data;
    if (data is Map && data['results'] is List) {
      return _page(raw, parse).results;
    }
    if (data is List) {
      return data
          .whereType<Map>()
          .map((Map row) => parse(Map<String, dynamic>.from(row)))
          .toList();
    }
    return <T>[];
  }

  Map<String, dynamic> _data(ApiEnvelope envelope) {
    try {
      return envelope.requireDataMap();
    } on FormatException {
      throw const UnknownException();
    }
  }

  ApiEnvelope _envelope(dynamic data) {
    try {
      final ApiEnvelope envelope = ApiEnvelope.parse(data);
      if (!envelope.success && envelope.data == null) {
        throw UnknownException(envelope.message ?? 'Request failed.');
      }
      return envelope;
    } on FormatException {
      throw const UnknownException();
    }
  }

  int _readInt(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
