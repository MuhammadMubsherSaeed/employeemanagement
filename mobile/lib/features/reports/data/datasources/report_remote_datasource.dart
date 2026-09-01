import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_base/core/constants/app_constants.dart';
import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/core/network/api_client.dart';
import 'package:flutter_base/core/network/models/api_envelope.dart';
import 'package:flutter_base/features/reports/data/report_endpoints.dart';
import 'package:flutter_base/features/reports/domain/entities/report_export.dart';
import 'package:flutter_base/features/reports/domain/entities/report_items.dart';
import 'package:flutter_base/features/reports/domain/entities/report_json.dart';
import 'package:flutter_base/features/reports/domain/entities/report_kind.dart';
import 'package:flutter_base/features/reports/domain/entities/report_query.dart';

abstract class ReportRemoteDataSource {
  Future<ReportPage<AttendanceReportItem>> getAttendanceReport(ReportQuery query);

  Future<ReportPage<LeaveReportItem>> getLeaveReport(ReportQuery query);

  Future<ReportPage<EmployeeReportItem>> getEmployeeReport(ReportQuery query);

  Future<ReportPage<DeviceReportItem>> getDeviceReport(ReportQuery query);

  Future<ReportExportFile> exportAttendanceReport(
    ReportQuery query,
    ReportExportFormat format,
  );

  Future<ReportExportFile> exportLeaveReport(
    ReportQuery query,
    ReportExportFormat format,
  );

  Future<ReportExportFile> exportEmployeeReport(
    ReportQuery query,
    ReportExportFormat format,
  );

  Future<ReportExportFile> exportDeviceReport(
    ReportQuery query,
    ReportExportFormat format,
  );
}

class ReportRemoteDataSourceImpl implements ReportRemoteDataSource {
  ReportRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  static const int exportReceiveTimeoutMs = 60000;

  @override
  Future<ReportPage<AttendanceReportItem>> getAttendanceReport(
    ReportQuery query,
  ) {
    return _list(
      ReportEndpoints.attendance,
      query,
      AttendanceReportItem.fromJson,
    );
  }

  @override
  Future<ReportPage<LeaveReportItem>> getLeaveReport(ReportQuery query) {
    return _list(ReportEndpoints.leaves, query, LeaveReportItem.fromJson);
  }

  @override
  Future<ReportPage<EmployeeReportItem>> getEmployeeReport(ReportQuery query) {
    return _list(
      ReportEndpoints.employees,
      query,
      EmployeeReportItem.fromJson,
    );
  }

  @override
  Future<ReportPage<DeviceReportItem>> getDeviceReport(ReportQuery query) {
    return _list(ReportEndpoints.devices, query, DeviceReportItem.fromJson);
  }

  @override
  Future<ReportExportFile> exportAttendanceReport(
    ReportQuery query,
    ReportExportFormat format,
  ) {
    return _export(
      ReportEndpoints.attendanceExport,
      query,
      format,
      ReportKind.attendance,
    );
  }

  @override
  Future<ReportExportFile> exportLeaveReport(
    ReportQuery query,
    ReportExportFormat format,
  ) {
    return _export(
      ReportEndpoints.leavesExport,
      query,
      format,
      ReportKind.leaves,
    );
  }

  @override
  Future<ReportExportFile> exportEmployeeReport(
    ReportQuery query,
    ReportExportFormat format,
  ) {
    return _export(
      ReportEndpoints.employeesExport,
      query,
      format,
      ReportKind.employees,
    );
  }

  @override
  Future<ReportExportFile> exportDeviceReport(
    ReportQuery query,
    ReportExportFormat format,
  ) {
    return _export(
      ReportEndpoints.devicesExport,
      query,
      format,
      ReportKind.devices,
    );
  }

  Future<ReportPage<T>> _list<T>(
    String path,
    ReportQuery query,
    T Function(Map<String, dynamic> json) parse,
  ) async {
    final Response<dynamic> response = await _client.get<dynamic>(
      path,
      queryParameters: query.sanitized().toQueryParameters(),
    );
    return _page(response.data, parse);
  }

  Future<ReportExportFile> _export(
    String path,
    ReportQuery query,
    ReportExportFormat format,
    ReportKind kind,
  ) async {
    final Map<String, dynamic> params = query
        .sanitized()
        .toQueryParameters(includePagination: false);
    params['format'] = format.apiValue;
    final Response<List<int>> response = await _client.get<List<int>>(
      path,
      queryParameters: params,
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: exportReceiveTimeoutMs,
        headers: <String, dynamic>{
          ApiHeaders.accept: '*/*',
        },
      ),
    );
    final Uint8List bytes = _bytes(response.data);
    _rejectJsonPayload(bytes, response.headers);
    if (bytes.isEmpty) {
      throw const UnknownException('The exported file was empty.');
    }
    final String contentType =
        response.headers.value(Headers.contentTypeHeader) ?? format.mimeType;
    if (!_looksLikeFile(contentType, format)) {
      throw const UnknownException('The server did not return an export file.');
    }
    return ReportExportFile(
      bytes: bytes,
      filename: _filename(response.headers, kind, format),
      mimeType: format.mimeType,
      format: format,
    );
  }

  ReportPage<T> _page<T>(
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
    return ReportPage<T>(
      results: items,
      count: readReportInt(data['count']) ?? items.length,
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

  Uint8List _bytes(List<int>? data) {
    if (data == null) {
      return Uint8List(0);
    }
    if (data is Uint8List) {
      return data;
    }
    return Uint8List.fromList(data);
  }

  void _rejectJsonPayload(Uint8List bytes, Headers headers) {
    final String contentType =
        (headers.value(Headers.contentTypeHeader) ?? '').toLowerCase();
    if (contentType.contains('json')) {
      throw const UnknownException('The server did not return an export file.');
    }
    if (bytes.isEmpty) {
      return;
    }
    final int first = bytes.first;
    if (first == 0x7B || first == 0x5B) {
      try {
        jsonDecode(utf8.decode(bytes));
        throw const UnknownException(
          'The server did not return an export file.',
        );
      } on UnknownException {
        rethrow;
      } catch (_) {
        return;
      }
    }
  }

  bool _looksLikeFile(String contentType, ReportExportFormat format) {
    final String type = contentType.toLowerCase();
    if (type.contains('json')) {
      return false;
    }
    switch (format) {
      case ReportExportFormat.csv:
        return type.contains('csv') ||
            type.contains('text/plain') ||
            type.contains('octet-stream') ||
            type.isEmpty;
      case ReportExportFormat.xlsx:
        return type.contains('spreadsheet') ||
            type.contains('excel') ||
            type.contains('octet-stream') ||
            type.isEmpty;
      case ReportExportFormat.pdf:
        return type.contains('pdf') ||
            type.contains('octet-stream') ||
            type.isEmpty;
    }
  }

  String _filename(
    Headers headers,
    ReportKind kind,
    ReportExportFormat format,
  ) {
    final String? header = headers.value('content-disposition');
    final String? parsed = _parseContentDisposition(header);
    if (parsed != null && parsed.isNotEmpty) {
      return parsed;
    }
    final String stamp = formatReportDateParam(DateTime.now());
    return '${kind.filenameStem}-$stamp.${format.apiValue}';
  }

  String? _parseContentDisposition(String? header) {
    if (header == null || header.isEmpty) {
      return null;
    }
    final RegExp utfName = RegExp("filename\\*=(?:UTF-8'')?([^;]+)", caseSensitive: false);
    final Match? starred = utfName.firstMatch(header);
    if (starred != null) {
      return Uri.decodeComponent(starred.group(1)!.replaceAll('"', '').trim());
    }
    final RegExp named = RegExp('filename="?([^";]+)"?', caseSensitive: false);
    final Match? match = named.firstMatch(header);
    if (match == null) {
      return null;
    }
    return match.group(1)?.trim();
  }
}
