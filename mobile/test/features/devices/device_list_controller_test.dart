import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/devices/domain/entities/device.dart';
import 'package:flutter_base/features/devices/domain/entities/device_enums.dart';
import 'package:flutter_base/features/devices/domain/entities/device_query.dart';
import 'package:flutter_base/features/devices/presentation/providers/device_history_controller.dart';
import 'package:flutter_base/features/devices/presentation/providers/device_list_controller.dart';
import 'package:flutter_base/features/devices/presentation/providers/device_providers.dart';
import 'package:flutter_base/features/devices/presentation/states/device_states.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/auth_fakes.dart';
import '../../helpers/device_fakes.dart';
import '../../helpers/employee_fakes.dart';

ProviderContainer _container(
  FakeDeviceRepository repository, {
  User user = sampleUser,
  AuthController Function()? auth,
}) {
  return ProviderContainer(
    overrides: <Override>[
      authControllerProvider.overrideWith(
        auth ?? () => SeededAuthController(user),
      ),
      deviceRepositoryProvider.overrideWithValue(repository),
    ],
  );
}

DevicePage<Device> _page({
  required int page,
  required bool hasMore,
  required List<Device> results,
  int count = 40,
}) {
  return DevicePage<Device>(
    results: results,
    count: count,
    next: hasMore
        ? 'http://example.com/api/v1/devices/?page=${page + 1}'
        : null,
  );
}

void main() {
  test('initial load, empty, and error states', () async {
    final FakeDeviceRepository empty = FakeDeviceRepository(
      devices: <Device>[],
    );
    final ProviderContainer container = _container(empty);
    addTearDown(container.dispose);

    await container
        .read(deviceListControllerProvider(DeviceListKind.inventory).notifier)
        .loadInitial();
    expect(
      container.read(deviceListControllerProvider(DeviceListKind.inventory)).isEmpty,
      isTrue,
    );

    empty.listError = const NetworkException();
    empty.devices = <Device>[sampleDevice()];
    await container
        .read(deviceListControllerProvider(DeviceListKind.inventory).notifier)
        .loadInitial();
    expect(
      container.read(deviceListControllerProvider(DeviceListKind.inventory)).error,
      contains('internet'),
    );
  });

  test('pagination loads the next page once and stops on the last page',
      () async {
    final FakeDeviceRepository repository = FakeDeviceRepository()
      ..delay = const Duration(milliseconds: 20)
      ..pageBuilder = (DeviceQuery query) {
        if (query.page == 1) {
          return _page(
            page: 1,
            hasMore: true,
            results: <Device>[sampleDevice(id: 'a')],
          );
        }
        return _page(
          page: 2,
          hasMore: false,
          results: <Device>[sampleDevice(id: 'b')],
        );
      };
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final DeviceListController controller = container.read(
      deviceListControllerProvider(DeviceListKind.inventory).notifier,
    );
    await controller.loadInitial();
    expect(
      container.read(deviceListControllerProvider(DeviceListKind.inventory)).hasMore,
      isTrue,
    );

    final Future<void> first = controller.loadMore();
    final Future<void> second = controller.loadMore();
    await Future.wait(<Future<void>>[first, second]);

    expect(repository.listCalls, 2);
    expect(
      container.read(deviceListControllerProvider(DeviceListKind.inventory)).items.length,
      2,
    );
    expect(
      container.read(deviceListControllerProvider(DeviceListKind.inventory)).hasMore,
      isFalse,
    );

    await controller.loadMore();
    expect(repository.listCalls, 2);
  });

  test('search is debounced and resets pagination', () async {
    final FakeDeviceRepository repository = FakeDeviceRepository();
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final DeviceListController controller = container.read(
      deviceListControllerProvider(DeviceListKind.inventory).notifier,
    );
    await controller.loadInitial();

    controller.setSearch('L');
    controller.setSearch('LA');
    controller.setSearch('LAP');
    expect(repository.listCalls, 1);

    await Future<void>.delayed(
      DeviceListController.searchDebounce + const Duration(milliseconds: 50),
    );
    expect(repository.listCalls, 2);
    expect(repository.listQueries.last.search, 'LAP');
    expect(repository.listQueries.last.page, 1);
  });

  test('filters and refresh reset to page one', () async {
    final FakeDeviceRepository repository = FakeDeviceRepository()
      ..pageBuilder = (DeviceQuery query) => _page(
            page: query.page,
            hasMore: query.page == 1,
            results: <Device>[sampleDevice(id: 'p${query.page}')],
          );
    final ProviderContainer container = _container(repository, user: managerUser);
    addTearDown(container.dispose);
    final DeviceListController controller = container.read(
      deviceListControllerProvider(DeviceListKind.inventory).notifier,
    );
    await controller.loadInitial();
    await controller.loadMore();
    expect(repository.listQueries.last.page, 2);

    await controller.refresh();
    expect(repository.listQueries.last.page, 1);

    await controller.applyFilters(
      const DeviceQuery(status: DeviceStatus.assigned, type: 'Laptop'),
    );
    expect(repository.listQueries.last.page, 1);
    expect(repository.listQueries.last.status, DeviceStatus.assigned);
    expect(repository.listQueries.last.type, 'Laptop');
  });

  test('my-devices always sends assigned=true and never an employee id',
      () async {
    final FakeDeviceRepository repository = FakeDeviceRepository();
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);

    await container
        .read(deviceListControllerProvider(DeviceListKind.mine).notifier)
        .applyFilters(
          const DeviceQuery(assigned: false, employeeId: 'someone-else'),
        );

    expect(repository.listQueries.single.assigned, isTrue);
    expect(repository.listQueries.single.employeeId, isNull);
  });

  test('employees cannot query another employee from inventory filters',
      () async {
    final FakeDeviceRepository repository = FakeDeviceRepository();
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);

    await container
        .read(deviceListControllerProvider(DeviceListKind.inventory).notifier)
        .applyFilters(const DeviceQuery(employeeId: 'someone-else'));

    expect(repository.listQueries.single.employeeId, isNull);
  });

  test('managers may send an employee filter supported by the API', () async {
    final FakeDeviceRepository repository = FakeDeviceRepository();
    final ProviderContainer container = _container(
      repository,
      user: managerUser,
    );
    addTearDown(container.dispose);

    await container
        .read(deviceListControllerProvider(DeviceListKind.inventory).notifier)
        .applyFilters(const DeviceQuery(employeeId: 'emp-9'));
    expect(repository.listQueries.single.employeeId, 'emp-9');
  });

  test('load-more errors can be retried without skipping a page', () async {
    int calls = 0;
    final FakeDeviceRepository repository = FakeDeviceRepository()
      ..pageBuilder = (DeviceQuery query) {
        calls += 1;
        if (query.page == 1) {
          return _page(
            page: 1,
            hasMore: true,
            results: <Device>[sampleDevice(id: 'a')],
          );
        }
        if (calls == 2) {
          throw const NetworkException();
        }
        return _page(
          page: 2,
          hasMore: false,
          results: <Device>[sampleDevice(id: 'b')],
        );
      };
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final DeviceListController controller = container.read(
      deviceListControllerProvider(DeviceListKind.inventory).notifier,
    );
    await controller.loadInitial();
    await controller.loadMore();
    expect(
      container.read(deviceListControllerProvider(DeviceListKind.inventory)).error,
      contains('internet'),
    );
    expect(
      container.read(deviceListControllerProvider(DeviceListKind.inventory)).items.length,
      1,
    );
    await controller.loadMore();
    expect(
      container.read(deviceListControllerProvider(DeviceListKind.inventory)).items.length,
      2,
    );
    expect(
      container.read(deviceListControllerProvider(DeviceListKind.inventory)).error,
      isNull,
    );
  });

  test('auth changes clear cached inventory so tenants are not mixed', () async {
    final FakeDeviceRepository repository = FakeDeviceRepository(
      devices: <Device>[sampleDevice(assetCode: 'CO-A')],
    );
    final SwitchingAuthController auth = SwitchingAuthController(companyAdminUser);
    final ProviderContainer container = _container(
      repository,
      auth: () => auth,
    );
    addTearDown(container.dispose);

    await container
        .read(deviceListControllerProvider(DeviceListKind.inventory).notifier)
        .loadInitial();
    expect(
      container.read(deviceListControllerProvider(DeviceListKind.inventory)).items.single.assetCode,
      'CO-A',
    );

    repository.devices = <Device>[sampleDevice(id: 'b', assetCode: 'CO-B')];
    auth.switchTo(managerUser);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(
      container.read(deviceListControllerProvider(DeviceListKind.inventory)).items.single.assetCode,
      'CO-B',
    );
  });

  test('history pagination follows the backend page contract', () async {
    final FakeDeviceRepository repository = FakeDeviceRepository()
      ..historyPageBuilder = (DeviceHistoryQuery query) {
        if (query.page == 1) {
          return DevicePage<DeviceHistoryItem>(
            results: <DeviceHistoryItem>[sampleHistoryItem(id: 'h1')],
            count: 2,
            next: 'http://example.com/api/v1/devices/dev-1/history/?page=2',
          );
        }
        return DevicePage<DeviceHistoryItem>(
          results: <DeviceHistoryItem>[sampleHistoryItem(id: 'h2')],
          count: 2,
        );
      };
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final DeviceHistoryController controller =
        container.read(deviceHistoryControllerProvider('dev-1').notifier);
    await controller.loadInitial();
    expect(
      container.read(deviceHistoryControllerProvider('dev-1')).hasMore,
      isTrue,
    );
    await controller.loadMore();
    expect(
      container.read(deviceHistoryControllerProvider('dev-1')).items.length,
      2,
    );
    expect(
      container.read(deviceHistoryControllerProvider('dev-1')).hasMore,
      isFalse,
    );
  });
}
