import 'package:flutter_base/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:flutter_base/features/settings/domain/entities/company_settings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/settings_fakes.dart';

void main() {
  test('repository GET and PATCH forward to the remote data source', () async {
    final FakeSettingsRemote remote = FakeSettingsRemote();
    final SettingsRepositoryImpl repository = SettingsRepositoryImpl(remote);

    final CompanySettings loaded = await repository.getSettings();
    expect(loaded.companyName, 'Acme');
    expect(remote.getCalls, 1);

    const CompanySettingsPatch patch = CompanySettingsPatch(
      timezone: 'Europe/London',
      overtimeEnabled: true,
    );
    final CompanySettings updated = await repository.updateSettings(patch);
    expect(updated.timezone, 'Europe/London');
    expect(updated.overtimeEnabled, isTrue);
    expect(remote.patchCalls, 1);
    expect(remote.lastPatch, patch);
  });
}
