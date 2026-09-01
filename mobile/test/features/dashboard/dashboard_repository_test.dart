import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dashboard_fakes.dart';

void main() {
  test('forwards admin, manager, and employee dashboard requests', () async {
    final FakeDashboardRemote remote = FakeDashboardRemote();
    final DashboardRepositoryImpl repository = DashboardRepositoryImpl(remote);

    expect((await repository.getAdminDashboard()).totalEmployees, 12);
    expect(remote.adminCalls, 1);
    expect((await repository.getManagerDashboard()).teamSize, 6);
    expect(remote.managerCalls, 1);
    expect((await repository.getEmployeeDashboard()).notificationsCount, 3);
    expect(remote.employeeCalls, 1);
  });

  test('propagates unauthorized, forbidden, and network errors', () async {
    final FakeDashboardRemote remote = FakeDashboardRemote()
      ..adminError = const UnauthorizedException()
      ..managerError = const ForbiddenException()
      ..employeeError = const NetworkException();
    final DashboardRepositoryImpl repository = DashboardRepositoryImpl(remote);

    expect(repository.getAdminDashboard(), throwsA(isA<UnauthorizedException>()));
    expect(repository.getManagerDashboard(), throwsA(isA<ForbiddenException>()));
    expect(repository.getEmployeeDashboard(), throwsA(isA<NetworkException>()));
  });
}
