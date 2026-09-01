import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/core/network/api_client.dart';
import 'package:flutter_base/core/network/models/api_envelope.dart';
import 'package:flutter_base/features/dashboard/data/dashboard_endpoints.dart';
import 'package:flutter_base/features/dashboard/domain/entities/dashboard.dart';

abstract class DashboardRemoteDataSource {
  Future<AdminDashboard> getAdminDashboard();

  Future<ManagerDashboard> getManagerDashboard();

  Future<EmployeeDashboard> getEmployeeDashboard();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  DashboardRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<AdminDashboard> getAdminDashboard() async {
    final response = await _client.get<dynamic>(DashboardEndpoints.admin);
    return AdminDashboard.fromJson(_data(_envelope(response.data)));
  }

  @override
  Future<ManagerDashboard> getManagerDashboard() async {
    final response = await _client.get<dynamic>(DashboardEndpoints.manager);
    return ManagerDashboard.fromJson(_data(_envelope(response.data)));
  }

  @override
  Future<EmployeeDashboard> getEmployeeDashboard() async {
    final response = await _client.get<dynamic>(DashboardEndpoints.employee);
    return EmployeeDashboard.fromJson(_data(_envelope(response.data)));
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
}
