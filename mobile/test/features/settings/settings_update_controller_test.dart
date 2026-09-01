import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/settings/domain/entities/company_settings.dart';
import 'package:flutter_base/features/settings/domain/usecases/settings_usecases.dart';
import 'package:flutter_base/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter_base/features/settings/presentation/providers/settings_update_controller.dart';
import 'package:flutter_base/features/settings/presentation/states/settings_update_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/employee_fakes.dart';
import '../../helpers/settings_fakes.dart';

ProviderContainer _container(FakeSettingsRepository repository) {
  return ProviderContainer(
    overrides: <Override>[
      authControllerProvider.overrideWith(
        () => SeededAuthController(companyAdminUser),
      ),
      getCompanySettingsUseCaseProvider.overrideWithValue(
        GetCompanySettings(repository),
      ),
      updateCompanySettingsUseCaseProvider.overrideWithValue(
        UpdateCompanySettings(repository),
      ),
    ],
  );
}

void main() {
  test('company settings provider loads then refreshes after a successful patch',
      () async {
    final FakeSettingsRepository repository = FakeSettingsRepository();
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);

    final CompanySettings loaded =
        await container.read(companySettingsProvider.future);
    expect(loaded.timezone, 'UTC');
    expect(repository.getCalls, 1);

    final SettingsUpdateController controller =
        container.read(settingsUpdateControllerProvider.notifier);
    final CompanySettings? updated = await controller.save(
      const CompanySettingsPatch(timezone: 'Europe/London'),
    );
    expect(updated?.timezone, 'Europe/London');
    expect(repository.patchCalls, 1);
    expect(repository.getCalls, 2);
    expect(
      container.read(companySettingsProvider).value?.timezone,
      'Europe/London',
    );
    expect(container.read(settingsUpdateControllerProvider).isSubmitting, isFalse);
  });

  test('duplicate submit is ignored while an update is in flight', () async {
    final FakeSettingsRepository repository = FakeSettingsRepository()
      ..delay = const Duration(milliseconds: 80);
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    await container.read(companySettingsProvider.future);

    final SettingsUpdateController controller =
        container.read(settingsUpdateControllerProvider.notifier);
    final Future<CompanySettings?> first = controller.save(
      const CompanySettingsPatch(gracePeriodMinutes: 20),
    );
    expect(container.read(settingsUpdateControllerProvider).isSubmitting, isTrue);
    final CompanySettings? second = await controller.save(
      const CompanySettingsPatch(gracePeriodMinutes: 30),
    );
    expect(second, isNull);
    await first;
    expect(repository.patchCalls, 1);
    expect(repository.lastPatch?.gracePeriodMinutes, 20);
  });

  test('API validation errors populate field errors and keep settings', () async {
    final FakeSettingsRepository repository = FakeSettingsRepository()
      ..patchError = const ValidationException(
        'Invalid timezone.',
        fieldErrors: <String, List<String>>{
          'timezone': <String>['Unknown IANA timezone.'],
        },
      );
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    await container.read(companySettingsProvider.future);

    final CompanySettings? result = await container
        .read(settingsUpdateControllerProvider.notifier)
        .save(const CompanySettingsPatch(timezone: 'Not/A_Zone'));
    expect(result, isNull);
    final SettingsUpdateState state =
        container.read(settingsUpdateControllerProvider);
    expect(state.isSubmitting, isFalse);
    expect(state.fieldErrors['timezone'], 'Unknown IANA timezone.');
    expect(state.error, 'Unknown IANA timezone.');
  });
}
