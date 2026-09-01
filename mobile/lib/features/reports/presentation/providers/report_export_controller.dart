import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_base/features/reports/domain/entities/report_export.dart';
import 'package:flutter_base/features/reports/domain/entities/report_kind.dart';
import 'package:flutter_base/features/reports/domain/entities/report_query.dart';
import 'package:flutter_base/features/reports/domain/report_access.dart';
import 'package:flutter_base/features/reports/presentation/providers/report_error_mapper.dart';
import 'package:flutter_base/features/reports/presentation/providers/report_providers.dart';
import 'package:flutter_base/features/reports/presentation/states/report_export_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReportExportController
    extends FamilyNotifier<ReportExportState, ReportKind> {
  bool _inFlight = false;

  @override
  ReportExportState build(ReportKind arg) {
    ref.listen<AuthState>(authControllerProvider, (_, AuthState next) {
      state = const ReportExportState();
    });
    return const ReportExportState();
  }

  Future<void> export(ReportQuery query, ReportExportFormat format) async {
    if (_inFlight || state.isBusy) {
      return;
    }
    final ReportQuery sanitized = query.sanitized();
    if (sanitized.hasInvalidDateRange) {
      state = ReportExportState(
        phase: ReportExportPhase.error,
        format: format,
        error: ReportErrorMapper.invalidRange,
      );
      return;
    }
    final AuthState auth = ref.read(authControllerProvider);
    final UserRole role =
        auth is AuthAuthenticated ? auth.user.role : UserRole.unknown;
    if (!ReportAccess(role).canExport) {
      state = ReportExportState(
        phase: ReportExportPhase.error,
        format: format,
        error: ReportErrorMapper.exportForbidden,
      );
      return;
    }
    _inFlight = true;
    state = ReportExportState(
      phase: ReportExportPhase.preparing,
      format: format,
    );
    try {
      state = state.copyWith(phase: ReportExportPhase.downloading);
      final ReportExportFile file = await _download(sanitized, format);
      final ReportSavedFile saved =
          await ref.read(reportFileServiceProvider).save(file);
      state = ReportExportState(
        phase: ReportExportPhase.success,
        format: format,
        file: saved,
      );
    } catch (error) {
      state = ReportExportState(
        phase: ReportExportPhase.error,
        format: format,
        error: ReportErrorMapper.message(error, export: true),
      );
    } finally {
      _inFlight = false;
    }
  }

  Future<void> share() async {
    final ReportSavedFile? file = state.file;
    if (file == null) {
      return;
    }
    await ref.read(reportFileServiceProvider).share(file);
  }

  Future<bool> open() async {
    final ReportSavedFile? file = state.file;
    if (file == null) {
      return false;
    }
    return ref.read(reportFileServiceProvider).open(file);
  }

  void clear() {
    if (state.isBusy) {
      return;
    }
    state = const ReportExportState();
  }

  Future<ReportExportFile> _download(
    ReportQuery query,
    ReportExportFormat format,
  ) {
    switch (arg) {
      case ReportKind.attendance:
        return ref.read(exportAttendanceReportProvider)(query, format);
      case ReportKind.leaves:
        return ref.read(exportLeaveReportProvider)(query, format);
      case ReportKind.employees:
        return ref.read(exportEmployeeReportProvider)(query, format);
      case ReportKind.devices:
        return ref.read(exportDeviceReportProvider)(query, format);
    }
  }
}

final reportExportControllerProvider = NotifierProvider.family<
    ReportExportController, ReportExportState, ReportKind>(
  ReportExportController.new,
);
