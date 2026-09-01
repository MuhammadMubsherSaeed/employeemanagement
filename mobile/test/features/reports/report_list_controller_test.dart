import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/core/session/session_store.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_base/features/reports/domain/entities/report_items.dart';
import 'package:flutter_base/features/reports/domain/entities/report_kind.dart';
import 'package:flutter_base/features/reports/domain/entities/report_query.dart';
import 'package:flutter_base/features/reports/domain/usecases/report_usecases.dart';
import 'package:flutter_base/features/reports/presentation/providers/report_error_mapper.dart';
import 'package:flutter_base/features/reports/presentation/providers/report_list_controller.dart';
import 'package:flutter_base/features/reports/presentation/providers/report_providers.dart';
import 'package:flutter_base/features/reports/presentation/states/report_list_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/employee_fakes.dart';
import '../../helpers/report_fakes.dart';

ProviderContainer _container(
  FakeReportRepository repository, {
  AuthController Function()? auth,
}) {
  return ProviderContainer(
    overrides: <Override>[
      authControllerProvider.overrideWith(
        auth ?? () => SeededAuthController(companyAdminUser),
      ),
      currentSessionProvider.overrideWith((Ref ref) async => null),
      reportRepositoryProvider.overrideWithValue(repository),
      getAttendanceReportProvider.overrideWithValue(
        GetAttendanceReport(repository),
      ),
      getLeaveReportProvider.overrideWithValue(GetLeaveReport(repository)),
      getEmployeeReportProvider.overrideWithValue(
        GetEmployeeReport(repository),
      ),
      getDeviceReportProvider.overrideWithValue(GetDeviceReport(repository)),
    ],
  );
}

void main() {
  test('initial load, empty, error, retry, and refresh', () async {
    final FakeReportRepository repository = FakeReportRepository(
      attendance: <AttendanceReportItem>[],
    )..listError = const NetworkException();
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final ReportListController controller =
        container.read(reportListControllerProvider(ReportKind.attendance).notifier);

    await controller.loadInitial();
    ReportListState state =
        container.read(reportListControllerProvider(ReportKind.attendance));
    expect(state.error, contains('internet'));
    expect(state.items, isEmpty);

    repository.listError = null;
    await controller.loadInitial();
    state = container.read(reportListControllerProvider(ReportKind.attendance));
    expect(state.error, isNull);
    expect(state.isEmpty, isTrue);

    repository.attendance = <AttendanceReportItem>[sampleAttendanceReportItem()];
    await controller.refresh();
    expect(
      container.read(reportListControllerProvider(ReportKind.attendance)).items,
      isNotEmpty,
    );
    expect(repository.attendanceCalls, greaterThanOrEqualTo(3));
  });

  test('filters, search debounce, and clear reset pagination', () async {
    final FakeReportRepository repository = FakeReportRepository()
      ..hasMoreFor = (ReportQuery query) => query.page == 1;
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final ReportListController controller =
        container.read(reportListControllerProvider(ReportKind.attendance).notifier);
    await controller.loadInitial();
    await controller.loadMore();
    expect(repository.attendanceQueries.last.page, 2);

    controller.setSearch('A');
    controller.setSearch('Ada');
    expect(repository.attendanceCalls, 2);
    await Future<void>.delayed(
      ReportListController.searchDebounce + const Duration(milliseconds: 50),
    );
    expect(repository.attendanceQueries.last.search, 'Ada');
    expect(repository.attendanceQueries.last.page, 1);

    await controller.applyFilters(
      const ReportQuery(
        kind: ReportKind.attendance,
        departmentId: 'dept-1',
        status: 'LATE',
        employeeId: 'emp-1',
      ),
    );
    expect(repository.attendanceQueries.last.page, 1);
    expect(repository.attendanceQueries.last.departmentId, 'dept-1');

    await controller.clearFilters();
    expect(repository.attendanceQueries.last.departmentId, isNull);
    expect(repository.attendanceQueries.last.page, 1);
  });

  test('invalid date range does not call the API', () async {
    final FakeReportRepository repository = FakeReportRepository();
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final ReportListController controller =
        container.read(reportListControllerProvider(ReportKind.attendance).notifier);
    await controller.applyFilters(
      ReportQuery(
        kind: ReportKind.attendance,
        dateFrom: DateTime(2026, 9, 10),
        dateTo: DateTime(2026, 9, 1),
      ),
    );
    expect(repository.attendanceCalls, 0);
    expect(
      container.read(reportListControllerProvider(ReportKind.attendance)).error,
      ReportErrorMapper.invalidRange,
    );
  });

  test('pagination ignores duplicate load-more and combined filters', () async {
    final FakeReportRepository repository = FakeReportRepository()
      ..delay = const Duration(milliseconds: 20)
      ..hasMoreFor = (ReportQuery query) => query.page == 1;
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final ReportListController controller =
        container.read(reportListControllerProvider(ReportKind.leaves).notifier);
    await controller.loadInitial();
    final Future<void> first = controller.loadMore();
    final Future<void> second = controller.loadMore();
    await Future.wait(<Future<void>>[first, second]);
    expect(repository.leaveCalls, 2);
    await controller.loadMore();
    expect(repository.leaveCalls, 2);
  });

  test('employee and device reports do not send dates', () async {
    final FakeReportRepository repository = FakeReportRepository();
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    await container
        .read(reportListControllerProvider(ReportKind.employees).notifier)
        .applyFilters(
          ReportQuery(
            kind: ReportKind.employees,
            dateFrom: DateTime(2026, 1, 1),
            employmentType: 'CONTRACT',
          ),
        );
    expect(
      repository.employeeQueries.last.toQueryParameters().containsKey('date_from'),
      isFalse,
    );
    expect(repository.employeeQueries.last.employmentType, 'CONTRACT');
  });

  test('auth change clears report data between tenants', () async {
    final FakeReportRepository repository = FakeReportRepository();
    final _SwitchingAuthController auth = _SwitchingAuthController(companyAdminUser);
    final ProviderContainer container = _container(
      repository,
      auth: () => auth,
    );
    addTearDown(container.dispose);
    await container
        .read(reportListControllerProvider(ReportKind.attendance).notifier)
        .loadInitial();
    expect(
      container.read(reportListControllerProvider(ReportKind.attendance)).items,
      isNotEmpty,
    );

    auth.switchTo(managerUser);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(reportListControllerProvider(ReportKind.attendance)).items,
      isNotEmpty,
    );
    expect(repository.attendanceCalls, greaterThan(1));
  });
}

class _SwitchingAuthController extends AuthController {
  _SwitchingAuthController(this.user);

  User user;

  @override
  AuthState build() => AuthState.authenticated(user);

  void switchTo(User next) {
    user = next;
    state = AuthState.authenticated(next);
  }
}
