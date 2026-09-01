import 'package:equatable/equatable.dart';
import 'package:flutter_base/features/reports/domain/entities/report_export.dart';
import 'package:flutter_base/features/reports/domain/entities/report_kind.dart';

enum ReportExportPhase { idle, preparing, downloading, success, error }

class ReportExportState extends Equatable {
  const ReportExportState({
    this.phase = ReportExportPhase.idle,
    this.format,
    this.file,
    this.error,
  });

  final ReportExportPhase phase;
  final ReportExportFormat? format;
  final ReportSavedFile? file;
  final String? error;

  bool get isBusy =>
      phase == ReportExportPhase.preparing ||
      phase == ReportExportPhase.downloading;

  ReportExportState copyWith({
    ReportExportPhase? phase,
    ReportExportFormat? format,
    ReportSavedFile? file,
    String? error,
    bool clearFile = false,
    bool clearError = false,
  }) {
    return ReportExportState(
      phase: phase ?? this.phase,
      format: format ?? this.format,
      file: clearFile ? null : (file ?? this.file),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => <Object?>[phase, format, file, error];
}
