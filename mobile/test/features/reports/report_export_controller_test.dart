import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/core/session/session_store.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/reports/domain/entities/report_kind.dart';
import 'package:flutter_base/features/reports/domain/entities/report_query.dart';
import 'package:flutter_base/features/reports/domain/usecases/report_usecases.dart';
import 'package:flutter_base/features/reports/presentation/providers/report_error_mapper.dart';
import 'package:flutter_base/features/reports/presentation/providers/report_export_controller.dart';
import 'package:flutter_base/features/reports/presentation/providers/report_providers.dart';
import 'package:flutter_base/features/reports/presentation/states/report_export_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/employee_fakes.dart';
import '../../helpers/report_fakes.dart';

ProviderContainer _container({
  required FakeReportRepository repository,
  required FakeReportFileService files,
  SeededAuthController Function()? auth,
}) {
  return ProviderContainer(
    overrides: <Override>[
      authControllerProvider.overrideWith(
        auth ?? () => SeededAuthController(companyAdminUser),
      ),
      currentSessionProvider.overrideWith((Ref ref) async => null),
      reportRepositoryProvider.overrideWithValue(repository),
      reportFileServiceProvider.overrideWithValue(files),
      exportAttendanceReportProvider.overrideWithValue(
        ExportAttendanceReport(repository),
      ),
      exportLeaveReportProvider.overrideWithValue(
        ExportLeaveReport(repository),
      ),
      exportEmployeeReportProvider.overrideWithValue(
        ExportEmployeeReport(repository),
      ),
      exportDeviceReportProvider.overrideWithValue(
        ExportDeviceReport(repository),
      ),
    ],
  );
}

void main() {
  test('exports csv, excel, and pdf using current filters', () async {
    final FakeReportRepository repository = FakeReportRepository();
    final FakeReportFileService files = FakeReportFileService();
    final ProviderContainer container = _container(
      repository: repository,
      files: files,
    );
    addTearDown(container.dispose);
    final ReportExportController controller = container.read(
      reportExportControllerProvider(ReportKind.attendance).notifier,
    );
    const ReportQuery query = ReportQuery(
      kind: ReportKind.attendance,
      status: 'LATE',
      search: 'Ada',
    );

    await controller.export(query, ReportExportFormat.csv);
    await controller.export(query, ReportExportFormat.xlsx);
    await controller.export(query, ReportExportFormat.pdf);

    expect(repository.exportCalls, 3);
    expect(
      repository.exportFormats,
      <ReportExportFormat>[
        ReportExportFormat.csv,
        ReportExportFormat.xlsx,
        ReportExportFormat.pdf,
      ],
    );
    expect(repository.exportQueries.last.status, 'LATE');
    expect(files.saved, hasLength(3));
    expect(
      container.read(reportExportControllerProvider(ReportKind.attendance)).phase,
      ReportExportPhase.success,
    );
  });

  test('duplicate export is ignored while in flight', () async {
    final FakeReportRepository repository = FakeReportRepository()
      ..delay = const Duration(milliseconds: 40);
    final FakeReportFileService files = FakeReportFileService();
    final ProviderContainer container = _container(
      repository: repository,
      files: files,
    );
    addTearDown(container.dispose);
    final ReportExportController controller = container.read(
      reportExportControllerProvider(ReportKind.leaves).notifier,
    );
    const ReportQuery query = ReportQuery(kind: ReportKind.leaves);
    final Future<void> first =
        controller.export(query, ReportExportFormat.csv);
    final Future<void> second =
        controller.export(query, ReportExportFormat.xlsx);
    await Future.wait(<Future<void>>[first, second]);
    expect(repository.exportCalls, 1);
    expect(repository.exportFormats.single, ReportExportFormat.csv);
  });

  test('manager without export permission does not call the API', () async {
    final FakeReportRepository repository = FakeReportRepository();
    final ProviderContainer container = _container(
      repository: repository,
      files: FakeReportFileService(),
      auth: () => SeededAuthController(managerUser),
    );
    addTearDown(container.dispose);
    await container
        .read(reportExportControllerProvider(ReportKind.attendance).notifier)
        .export(
          const ReportQuery(kind: ReportKind.attendance),
          ReportExportFormat.csv,
        );
    expect(repository.exportCalls, 0);
    expect(
      container.read(reportExportControllerProvider(ReportKind.attendance)).error,
      ReportErrorMapper.exportForbidden,
    );
  });

  test('forbidden and network export failures stay in error without retry',
      () async {
    final FakeReportRepository repository = FakeReportRepository()
      ..exportError = const ForbiddenException();
    final ProviderContainer container = _container(
      repository: repository,
      files: FakeReportFileService(),
    );
    addTearDown(container.dispose);
    final ReportExportController controller = container.read(
      reportExportControllerProvider(ReportKind.devices).notifier,
    );
    await controller.export(
      const ReportQuery(kind: ReportKind.devices),
      ReportExportFormat.pdf,
    );
    expect(
      container.read(reportExportControllerProvider(ReportKind.devices)).error,
      ReportErrorMapper.exportForbidden,
    );
    expect(repository.exportCalls, 1);

    repository.exportError = const NetworkException();
    await controller.export(
      const ReportQuery(kind: ReportKind.devices),
      ReportExportFormat.csv,
    );
    expect(
      container.read(reportExportControllerProvider(ReportKind.devices)).error,
      contains('internet'),
    );
  });

  test('share and open use the saved file', () async {
    final FakeReportFileService files = FakeReportFileService();
    final ProviderContainer container = _container(
      repository: FakeReportRepository(),
      files: files,
    );
    addTearDown(container.dispose);
    final ReportExportController controller = container.read(
      reportExportControllerProvider(ReportKind.employees).notifier,
    );
    await controller.export(
      const ReportQuery(kind: ReportKind.employees),
      ReportExportFormat.csv,
    );
    await controller.share();
    await controller.open();
    expect(files.shared, hasLength(1));
    expect(files.opened, hasLength(1));
    expect(files.shared.single.filename, contains('attendance-report'));
  });

  test('invalid date range blocks export', () async {
    final FakeReportRepository repository = FakeReportRepository();
    final ProviderContainer container = _container(
      repository: repository,
      files: FakeReportFileService(),
    );
    addTearDown(container.dispose);
    await container
        .read(reportExportControllerProvider(ReportKind.attendance).notifier)
        .export(
          ReportQuery(
            kind: ReportKind.attendance,
            dateFrom: DateTime(2026, 9, 10),
            dateTo: DateTime(2026, 9, 1),
          ),
          ReportExportFormat.csv,
        );
    expect(repository.exportCalls, 0);
  });
}
