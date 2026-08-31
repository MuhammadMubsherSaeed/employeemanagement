import 'package:dio/dio.dart';
import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/core/network/api_client.dart';
import 'package:flutter_base/core/network/models/api_envelope.dart';
import 'package:flutter_base/features/leaves/data/leave_endpoints.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave_query.dart';

abstract class LeaveRemoteDataSource {
  Future<LeavePage<LeaveType>> getLeaveTypes(LeaveTypeQuery query);

  Future<LeaveType> getLeaveType(String id);

  Future<LeaveType> createLeaveType(LeaveTypeWrite body);

  Future<LeaveType> updateLeaveType(String id, LeaveTypeWrite body);

  Future<LeavePage<LeaveBalance>> getLeaveBalances(LeaveBalanceQuery query);

  Future<LeaveBalance> allocateLeaveBalance({
    required String id,
    required int allocatedDays,
  });

  Future<LeavePage<LeaveRequest>> getLeaveRequests(LeaveRequestQuery query);

  Future<LeaveRequest> getLeaveRequest(String id);

  Future<LeaveRequest> createLeaveRequest(CreateLeaveRequestBody body);

  Future<LeaveRequest> approveLeaveRequest(String id);

  Future<LeaveRequest> rejectLeaveRequest({
    required String id,
    required String rejectionReason,
  });

  Future<LeaveRequest> cancelLeaveRequest(String id);
}

class LeaveRemoteDataSourceImpl implements LeaveRemoteDataSource {
  LeaveRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<LeavePage<LeaveType>> getLeaveTypes(LeaveTypeQuery query) async {
    final response = await _client.get<dynamic>(
      LeaveEndpoints.types,
      queryParameters: query.toQueryParameters(),
    );
    return _page(response.data, LeaveType.fromJson);
  }

  @override
  Future<LeaveType> getLeaveType(String id) async {
    final response = await _client.get<dynamic>(LeaveEndpoints.type(id));
    return LeaveType.fromJson(_data(_envelope(response.data)));
  }

  @override
  Future<LeaveType> createLeaveType(LeaveTypeWrite body) async {
    final response = await _client.post<dynamic>(
      LeaveEndpoints.types,
      data: body.toJson(),
    );
    return LeaveType.fromJson(_data(_envelope(response.data)));
  }

  @override
  Future<LeaveType> updateLeaveType(String id, LeaveTypeWrite body) async {
    final response = await _client.patch<dynamic>(
      LeaveEndpoints.type(id),
      data: body.toJson(),
    );
    return LeaveType.fromJson(_data(_envelope(response.data)));
  }

  @override
  Future<LeavePage<LeaveBalance>> getLeaveBalances(
    LeaveBalanceQuery query,
  ) async {
    final response = await _client.get<dynamic>(
      LeaveEndpoints.balances,
      queryParameters: query.toQueryParameters(),
    );
    return _page(response.data, LeaveBalance.fromJson);
  }

  @override
  Future<LeaveBalance> allocateLeaveBalance({
    required String id,
    required int allocatedDays,
  }) async {
    final response = await _client.patch<dynamic>(
      LeaveEndpoints.balance(id),
      data: <String, dynamic>{'allocated_days': allocatedDays},
    );
    return LeaveBalance.fromJson(_data(_envelope(response.data)));
  }

  @override
  Future<LeavePage<LeaveRequest>> getLeaveRequests(
    LeaveRequestQuery query,
  ) async {
    final response = await _client.get<dynamic>(
      LeaveEndpoints.requests,
      queryParameters: query.toQueryParameters(),
    );
    return _page(response.data, LeaveRequest.fromJson);
  }

  @override
  Future<LeaveRequest> getLeaveRequest(String id) async {
    final response = await _client.get<dynamic>(LeaveEndpoints.request(id));
    return LeaveRequest.fromJson(_data(_envelope(response.data)));
  }

  @override
  Future<LeaveRequest> createLeaveRequest(CreateLeaveRequestBody body) async {
    final Object payload;
    if (body.attachment == null) {
      payload = body.toJson();
    } else {
      payload = FormData.fromMap(<String, dynamic>{
        ...body.toJson(),
        'attachment': await MultipartFile.fromFile(
          body.attachment!.path,
          filename: body.attachment!.name,
        ),
      });
    }
    final response = await _client.post<dynamic>(
      LeaveEndpoints.requests,
      data: payload,
    );
    return LeaveRequest.fromJson(_data(_envelope(response.data)));
  }

  @override
  Future<LeaveRequest> approveLeaveRequest(String id) async {
    final response = await _client.post<dynamic>(
      LeaveEndpoints.approve(id),
      data: <String, dynamic>{},
    );
    return LeaveRequest.fromJson(_data(_envelope(response.data)));
  }

  @override
  Future<LeaveRequest> rejectLeaveRequest({
    required String id,
    required String rejectionReason,
  }) async {
    final response = await _client.post<dynamic>(
      LeaveEndpoints.reject(id),
      data: <String, dynamic>{'rejection_reason': rejectionReason},
    );
    return LeaveRequest.fromJson(_data(_envelope(response.data)));
  }

  @override
  Future<LeaveRequest> cancelLeaveRequest(String id) async {
    final response = await _client.post<dynamic>(
      LeaveEndpoints.cancel(id),
      data: <String, dynamic>{},
    );
    return LeaveRequest.fromJson(_data(_envelope(response.data)));
  }

  LeavePage<T> _page<T>(
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
    return LeavePage<T>(
      results: items,
      count: _readInt(data['count'], fallback: items.length),
      next: data['next']?.toString(),
      previous: data['previous']?.toString(),
    );
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
