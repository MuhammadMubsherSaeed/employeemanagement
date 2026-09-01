import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_base/features/reports/domain/entities/report_kind.dart';

class ReportExportFile extends Equatable {
  const ReportExportFile({
    required this.bytes,
    required this.filename,
    required this.mimeType,
    required this.format,
  });

  final Uint8List bytes;
  final String filename;
  final String mimeType;
  final ReportExportFormat format;

  @override
  List<Object?> get props => <Object?>[bytes, filename, mimeType, format];
}

class ReportSavedFile extends Equatable {
  const ReportSavedFile({
    required this.path,
    required this.filename,
    required this.mimeType,
  });

  final String path;
  final String filename;
  final String mimeType;

  @override
  List<Object?> get props => <Object?>[path, filename, mimeType];
}
