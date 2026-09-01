import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_base/core/constants/app_constants.dart';
import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/core/network/api_client.dart';
import 'package:flutter_base/core/network/models/api_envelope.dart';
import 'package:flutter_base/features/documents/data/document_endpoints.dart';
import 'package:flutter_base/features/documents/domain/entities/document.dart';
import 'package:flutter_base/features/documents/domain/entities/document_query.dart';

abstract class DocumentRemoteDataSource {
  Future<DocumentPage<EmployeeDocument>> listDocuments({
    required String employeeId,
    required DocumentQuery query,
  });

  Future<EmployeeDocument> getDocument({
    required String employeeId,
    required String documentId,
  });

  Future<EmployeeDocument> uploadDocument({
    required String employeeId,
    required DocumentType documentType,
    required DocumentFile file,
    String? title,
  });

  Future<void> deleteDocument({
    required String employeeId,
    required String documentId,
  });

  Future<DownloadedBytes> downloadDocument({
    required String employeeId,
    required String documentId,
  });
}

class DocumentRemoteDataSourceImpl implements DocumentRemoteDataSource {
  DocumentRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<DocumentPage<EmployeeDocument>> listDocuments({
    required String employeeId,
    required DocumentQuery query,
  }) async {
    final Response<dynamic> response = await _client.get<dynamic>(
      DocumentEndpoints.list(employeeId),
      queryParameters: query.toQueryParameters(),
    );
    return _page(response.data);
  }

  @override
  Future<EmployeeDocument> getDocument({
    required String employeeId,
    required String documentId,
  }) async {
    final Response<dynamic> response = await _client.get<dynamic>(
      DocumentEndpoints.detail(employeeId, documentId),
    );
    return EmployeeDocument.fromJson(_data(_envelope(response.data)));
  }

  @override
  Future<EmployeeDocument> uploadDocument({
    required String employeeId,
    required DocumentType documentType,
    required DocumentFile file,
    String? title,
  }) async {
    final FormData payload = FormData.fromMap(<String, dynamic>{
      'document_type': documentType.apiValue,
      if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
      'file': await MultipartFile.fromFile(file.path, filename: file.name),
    });
    final Response<dynamic> response = await _client.post<dynamic>(
      DocumentEndpoints.list(employeeId),
      data: payload,
    );
    return EmployeeDocument.fromJson(_data(_envelope(response.data)));
  }

  @override
  Future<void> deleteDocument({
    required String employeeId,
    required String documentId,
  }) async {
    await _client.delete<dynamic>(
      DocumentEndpoints.detail(employeeId, documentId),
    );
  }

  @override
  Future<DownloadedBytes> downloadDocument({
    required String employeeId,
    required String documentId,
  }) async {
    final Response<List<int>> response = await _client.get<List<int>>(
      DocumentEndpoints.download(employeeId, documentId),
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: AppConstants.dioTimeoutMs,
        headers: <String, dynamic>{
          ApiHeaders.accept: '*/*',
        },
      ),
    );
    final Uint8List bytes = _bytes(response.data);
    if (bytes.isEmpty) {
      throw const UnknownException('The file was empty.');
    }
    final String contentType =
        response.headers.value(Headers.contentTypeHeader) ??
            'application/octet-stream';
    if (contentType.toLowerCase().contains('json')) {
      throw const UnknownException('The server did not return a file.');
    }
    return DownloadedBytes(
      bytes: bytes,
      filename: _filename(response.headers) ?? 'document',
      mimeType: contentType.split(';').first.trim(),
    );
  }

  DocumentPage<EmployeeDocument> _page(dynamic raw) {
    final Map<String, dynamic> data = _data(_envelope(raw));
    final Object? results = data['results'];
    final List<EmployeeDocument> items = <EmployeeDocument>[];
    if (results is List) {
      for (final Object? row in results) {
        if (row is Map) {
          items.add(
            EmployeeDocument.fromJson(Map<String, dynamic>.from(row)),
          );
        }
      }
    }
    return DocumentPage<EmployeeDocument>(
      results: items,
      count: _readInt(data['count']) ?? items.length,
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

  String? _filename(Headers headers) {
    final String? header = headers.value('content-disposition');
    if (header == null || header.isEmpty) {
      return null;
    }
    final RegExp utfName =
        RegExp("filename\\*=(?:UTF-8'')?([^;]+)", caseSensitive: false);
    final Match? starred = utfName.firstMatch(header);
    if (starred != null) {
      return Uri.decodeComponent(starred.group(1)!.replaceAll('"', '').trim());
    }
    final RegExp named = RegExp('filename="?([^";]+)"?', caseSensitive: false);
    final Match? match = named.firstMatch(header);
    return match?.group(1)?.trim();
  }

  int? _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }
}
