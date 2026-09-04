import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/core/network/api_client.dart';
import 'package:flutter_base/core/network/models/api_envelope.dart';
import 'package:flutter_base/features/audit_logs/data/audit_log_endpoints.dart';
import 'package:flutter_base/features/audit_logs/domain/entities/audit_log.dart';

abstract class AuditLogRemoteDataSource {
  Future<AuditLogPage<AuditLogEntry>> getLogs({int page = 1});
}

class AuditLogRemoteDataSourceImpl implements AuditLogRemoteDataSource {
  AuditLogRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<AuditLogPage<AuditLogEntry>> getLogs({int page = 1}) async {
    final response = await _client.get<dynamic>(
      AuditLogEndpoints.logs,
      queryParameters: <String, dynamic>{'page': page},
    );
    final Map<String, dynamic> data = _data(_envelope(response.data));
    final Object? results = data['results'];
    final List<AuditLogEntry> items = <AuditLogEntry>[];
    if (results is List) {
      for (final Object? row in results) {
        if (row is Map) {
          items.add(AuditLogEntry.fromJson(Map<String, dynamic>.from(row)));
        }
      }
    }
    return AuditLogPage<AuditLogEntry>(
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
