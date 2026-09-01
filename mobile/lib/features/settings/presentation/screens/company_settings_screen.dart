import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_base/core/extensions/context_extensions.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_button.dart';
import 'package:flutter_base/core/widgets/app_card.dart';
import 'package:flutter_base/core/widgets/app_dialog.dart';
import 'package:flutter_base/core/widgets/app_dropdown.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:flutter_base/core/widgets/app_loader.dart';
import 'package:flutter_base/core/widgets/app_text_field.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_base/features/settings/domain/entities/company_settings.dart';
import 'package:flutter_base/features/settings/domain/iana_timezones.dart';
import 'package:flutter_base/features/settings/domain/settings_access.dart';
import 'package:flutter_base/features/settings/domain/settings_validation.dart';
import 'package:flutter_base/features/settings/presentation/providers/settings_error_mapper.dart';
import 'package:flutter_base/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter_base/features/settings/presentation/providers/settings_update_controller.dart';
import 'package:flutter_base/features/settings/presentation/states/settings_update_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CompanySettingsScreen extends ConsumerStatefulWidget {
  const CompanySettingsScreen({super.key});

  @override
  ConsumerState<CompanySettingsScreen> createState() =>
      _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends ConsumerState<CompanySettingsScreen> {
  final TextEditingController _name = TextEditingController();
  String _timezone = '';
  SettingsLogoFile? _pickedLogo;
  bool _hydrated = false;
  CompanySettings? _original;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  SettingsAccess get _access {
    final AuthState auth = ref.read(authControllerProvider);
    return SettingsAccess(
      auth is AuthAuthenticated ? auth.user.role : UserRole.unknown,
    );
  }

  bool get _dirty {
    final CompanySettings? original = _original;
    if (original == null) {
      return false;
    }
    return _name.text.trim() != original.companyName ||
        _timezone != original.timezone ||
        _pickedLogo != null;
  }

  void _hydrate(CompanySettings settings) {
    if (_hydrated && _original?.updatedAt == settings.updatedAt) {
      return;
    }
    _original = settings;
    _name.text = settings.companyName;
    _timezone = settings.timezone;
    _pickedLogo = null;
    _hydrated = true;
  }

  Future<bool> _confirmLeave() async {
    if (!_dirty) {
      return true;
    }
    final bool? leave = await AppDialog.confirm(
      context: context,
      title: 'Discard changes?',
      message: 'You have unsaved company settings.',
      confirmLabel: 'Discard',
    );
    return leave == true;
  }

  Future<void> _pickLogo() async {
    final SettingsLogoFile? file =
        await ref.read(settingsLogoPickerProvider).pick();
    if (file == null) {
      return;
    }
    final String? error = SettingsValidation.logoFile(file);
    if (error != null) {
      if (mounted) {
        context.showSnack(error);
      }
      return;
    }
    setState(() => _pickedLogo = file);
  }

  Future<void> _save() async {
    if (!_access.canEdit) {
      return;
    }
    final SettingsUpdateState update = ref.read(settingsUpdateControllerProvider);
    if (update.isSubmitting) {
      return;
    }
    final Map<String, String> local = SettingsValidation.company(
      companyName: _name.text,
      timezone: _timezone,
      logo: _pickedLogo,
    );
    if (local.isNotEmpty) {
      ref.read(settingsUpdateControllerProvider.notifier).setFieldErrors(local);
      return;
    }
    final CompanySettings? saved =
        await ref.read(settingsUpdateControllerProvider.notifier).save(
              CompanySettingsPatch(
                companyName: _name.text.trim(),
                timezone: _timezone,
                logo: _pickedLogo,
              ),
            );
    if (!mounted) {
      return;
    }
    if (saved != null) {
      setState(() {
        _original = saved;
        _pickedLogo = null;
        _hydrated = true;
        _name.text = saved.companyName;
        _timezone = saved.timezone;
      });
      context.showSnack('Company settings saved.');
    } else {
      final String? error = ref.read(settingsUpdateControllerProvider).error;
      if (error != null) {
        context.showSnack(error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<CompanySettings> async = ref.watch(companySettingsProvider);
    final SettingsUpdateState update = ref.watch(settingsUpdateControllerProvider);
    final bool canEdit = _access.canEdit;

    return PopScope(
      canPop: !_dirty || update.isSubmitting,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }
        final GoRouter router = GoRouter.of(context);
        final bool leave = await _confirmLeave();
        if (!leave) {
          return;
        }
        router.pop();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Company')),
        body: async.when(
          loading: () => const AppLoader(),
          error: (Object error, _) => AppErrorWidget(
            message: SettingsErrorMapper.message(error),
            onRetry: () => ref.invalidate(companySettingsProvider),
          ),
          data: (CompanySettings settings) {
            _hydrate(settings);
            final Map<String, String> errors = update.fieldErrors;
            return ListView(
              padding: AppSpacing.screen,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: <Widget>[
                if (!canEdit)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Text(
                      'You can view these settings. Only administrators can change them.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      AppTextField(
                        controller: _name,
                        label: 'Company name',
                        enabled: canEdit && !update.isSubmitting,
                        errorText: errors['company_name'],
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppDropdown<String>(
                        label: 'Timezone',
                        value: timezoneOptionsFor(_timezone).contains(_timezone)
                            ? _timezone
                            : null,
                        enabled: canEdit && !update.isSubmitting,
                        errorText: errors['timezone'],
                        items: timezoneOptionsFor(_timezone)
                            .map(
                              (String zone) => AppDropdownItem<String>(
                                value: zone,
                                label: zone.replaceAll('_', ' '),
                              ),
                            )
                            .toList(),
                        onChanged: (String? value) {
                          if (value == null) {
                            return;
                          }
                          setState(() => _timezone = value);
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Logo', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: AppSpacing.sm),
                      _LogoPreview(
                        networkUrl: settings.logo,
                        picked: _pickedLogo,
                      ),
                      if (errors['logo'] != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          errors['logo']!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                      ],
                      if (canEdit) ...<Widget>[
                        const SizedBox(height: AppSpacing.sm),
                        AppButton(
                          label: _pickedLogo == null
                              ? 'Choose logo'
                              : 'Change selected logo',
                          variant: AppButtonVariant.outlined,
                          onPressed: update.isSubmitting ? null : _pickLogo,
                        ),
                      ],
                    ],
                  ),
                ),
                if (canEdit) ...<Widget>[
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: 'Save',
                    isLoading: update.isSubmitting,
                    onPressed: update.isSubmitting ? null : _save,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LogoPreview extends StatelessWidget {
  const _LogoPreview({this.networkUrl, this.picked});

  final String? networkUrl;
  final SettingsLogoFile? picked;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppSpacing.sm);
    Widget child;
    if (picked != null) {
      child = Image.file(
        File(picked!.path),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _LogoPlaceholder(),
      );
    } else if (networkUrl != null && networkUrl!.isNotEmpty) {
      child = Image.network(
        networkUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _LogoPlaceholder(),
      );
    } else {
      child = const _LogoPlaceholder();
    }
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(width: 96, height: 96, child: child),
    );
  }
}

class _LogoPlaceholder extends StatelessWidget {
  const _LogoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.image_outlined)),
    );
  }
}
