import 'package:flutter_base/core/network/api_client_provider.dart';
import 'package:flutter_base/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:flutter_base/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:flutter_base/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:flutter_base/features/dashboard/domain/usecases/dashboard_usecases.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardRemoteDataSourceProvider =
    Provider<DashboardRemoteDataSource>((Ref ref) {
  return DashboardRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((Ref ref) {
  return DashboardRepositoryImpl(ref.watch(dashboardRemoteDataSourceProvider));
});

final getAdminDashboardUseCaseProvider = Provider<GetAdminDashboard>((Ref ref) {
  return GetAdminDashboard(ref.watch(dashboardRepositoryProvider));
});

final getManagerDashboardUseCaseProvider =
    Provider<GetManagerDashboard>((Ref ref) {
  return GetManagerDashboard(ref.watch(dashboardRepositoryProvider));
});

final getEmployeeDashboardUseCaseProvider =
    Provider<GetEmployeeDashboard>((Ref ref) {
  return GetEmployeeDashboard(ref.watch(dashboardRepositoryProvider));
});
