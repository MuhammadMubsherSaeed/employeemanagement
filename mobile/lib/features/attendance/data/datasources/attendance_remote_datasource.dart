import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/core/network/api_client.dart';
import 'package:flutter_base/core/network/models/api_envelope.dart';
import 'package:flutter_base/features/attendance/data/attendance_endpoints.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance_query.dart';

abstract class AttendanceRemoteDataSource {
  Future<AttendancePage<AttendanceRecord>> getMyAttendance(AttendanceQuery query);

  Future<AttendancePage<AttendanceRecord>> getAttendanceHistory(
    AttendanceQuery query,
  );

  Future<AttendanceRecord> getAttendanceById(String id);

  Future<AttendanceSummary> getAttendanceSummary(AttendanceSummaryQuery query);

  Future<AttendanceRecord> checkIn(CheckInOutBody body);

  Future<AttendanceRecord> checkOut(CheckInOutBody body);
}

class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  AttendanceRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<AttendancePage<AttendanceRecord>> getMyAttendance(
    AttendanceQuery query,
  ) async {
    final response = await _client.get<dynamic>(
      AttendanceEndpoints.me,
      queryParameters: query.toQueryParameters(),
    );
    return _page(response.data, AttendanceRecord.fromJson);
  }

  @override
  Future<AttendancePage<AttendanceRecord>> getAttendanceHistory(
    AttendanceQuery query,
  ) async {
    final response = await _client.get<dynamic>(
      AttendanceEndpoints.attendance,
      queryParameters: query.toQueryParameters(),
    );
    return _page(response.data, AttendanceRecord.fromJson);
  }

  @override
  Future<AttendanceRecord> getAttendanceById(String id) async {
    final response = await _client.get<dynamic>(AttendanceEndpoints.detail(id));
    return AttendanceRecord.fromJson(_data(_envelope(response.data)));
  }

  @override
  Future<AttendanceSummary> getAttendanceSummary(
    AttendanceSummaryQuery query,
  ) async {
    final response = await _client.get<dynamic>(
      AttendanceEndpoints.summary,
      queryParameters: query.toQueryParameters(),
    );
    return AttendanceSummary.fromJson(_data(_envelope(response.data)));
  }

  @override
  Future<AttendanceRecord> checkIn(CheckInOutBody body) async {
    final response = await _client.post<dynamic>(
      AttendanceEndpoints.checkIn,
      data: body.toJson(),
    );
    return AttendanceRecord.fromJson(_data(_envelope(response.data)));
  }

  @override
  Future<AttendanceRecord> checkOut(CheckInOutBody body) async {
    final response = await _client.post<dynamic>(
      AttendanceEndpoints.checkOut,
      data: body.toJson(),
    );
    return AttendanceRecord.fromJson(_data(_envelope(response.data)));
  }

  AttendancePage<T> _page<T>(
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
    return AttendancePage<T>(
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
