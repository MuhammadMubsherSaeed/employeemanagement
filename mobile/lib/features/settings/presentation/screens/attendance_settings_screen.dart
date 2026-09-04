import 'package:flutter/material.dart';
import 'package:flutter_base/core/extensions/context_extensions.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_button.dart';
import 'package:flutter_base/core/widgets/app_card.dart';
import 'package:flutter_base/core/widgets/app_dialog.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:flutter_base/core/widgets/app_loader.dart';
import 'package:flutter_base/core/widgets/app_text_field.dart';
import 'package:flutter_base/core/auth/authorization_providers.dart';
import 'package:flutter_base/features/settings/domain/entities/company_settings.dart';
import 'package:flutter_base/features/settings/domain/settings_access.dart';
import 'package:flutter_base/features/settings/domain/settings_validation.dart';
import 'package:flutter_base/features/settings/presentation/providers/settings_error_mapper.dart';
import 'package:flutter_base/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter_base/features/settings/presentation/providers/settings_update_controller.dart';
import 'package:flutter_base/features/settings/presentation/states/settings_update_state.dart';
import 'package:flutter_base/features/settings/presentation/widgets/working_days_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AttendanceSettingsScreen extends ConsumerStatefulWidget {
  const AttendanceSettingsScreen({super.key});

  @override
  ConsumerState<AttendanceSettingsScreen> createState() =>
      _AttendanceSettingsScreenState();
}

class _AttendanceSettingsScreenState
    extends ConsumerState<AttendanceSettingsScreen> {
  ClockTime _start = const ClockTime(hour: 0, minute: 0);
  ClockTime _end = const ClockTime(hour: 0, minute: 1);
  final TextEditingController _grace = TextEditingController();
  final TextEditingController _minimum = TextEditingController();
  bool _overtime = false;
  List<String> _days = const <String>[];
  bool _hydrated = false;
  CompanySettings? _original;

  @override
  void dispose() {
    _grace.dispose();
    _minimum.dispose();
    super.dispose();
  }

  SettingsAccess get _access {
    return SettingsAccess(ref.read(authorizationProvider));
  }

  bool get _dirty {
    final CompanySettings? original = _original;
    if (original == null) {
      return false;
    }
    return _start != original.workStartTime ||
        _end != original.workEndTime ||
        _grace.text.trim() != '${original.gracePeriodMinutes}' ||
        _minimum.text.trim() != '${original.minimumWorkingMinutes}' ||
        _overtime != original.overtimeEnabled ||
        !_sameDays(_days, original.workingDays);
  }

  void _hydrate(CompanySettings settings) {
    if (_hydrated && _original?.updatedAt == settings.updatedAt) {
      return;
    }
    _original = settings;
    _start = settings.workStartTime;
    _end = settings.workEndTime;
    _grace.text = '${settings.gracePeriodMinutes}';
    _minimum.text = '${settings.minimumWorkingMinutes}';
    _overtime = settings.overtimeEnabled;
    _days = List<String>.from(settings.workingDays);
    _hydrated = true;
  }

  Future<bool> _confirmLeave() async {
    if (!_dirty) {
      return true;
    }
    final bool? leave = await AppDialog.confirm(
      context: context,
      title: 'Discard changes?',
      message: 'You have unsaved attendance settings.',
      confirmLabel: 'Discard',
    );
    return leave == true;
  }

  Future<void> _pickTime({required bool start}) async {
    if (!_access.canEdit) {
      return;
    }
    final ClockTime current = start ? _start : _end;
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      final ClockTime next = ClockTime(hour: picked.hour, minute: picked.minute);
      if (start) {
        _start = next;
      } else {
        _end = next;
      }
    });
  }

  Future<void> _save() async {
    if (!_access.canEdit) {
      return;
    }
    final SettingsUpdateState update = ref.read(settingsUpdateControllerProvider);
    if (update.isSubmitting) {
      return;
    }
    final int? grace = int.tryParse(_grace.text.trim());
    final int? minimum = int.tryParse(_minimum.text.trim());
    final Map<String, String> local = <String, String>{};
    if (grace == null) {
      local['grace_period_minutes'] = 'Enter a whole number of minutes.';
    }
    if (minimum == null) {
      local['minimum_working_minutes'] = 'Enter a whole number of minutes.';
    }
    if (grace != null && minimum != null) {
      local.addAll(
        SettingsValidation.attendance(
          workStartTime: _start,
          workEndTime: _end,
          gracePeriodMinutes: grace,
          minimumWorkingMinutes: minimum,
          workingDays: _days,
        ),
      );
    }
    if (local.isNotEmpty) {
      ref.read(settingsUpdateControllerProvider.notifier).setFieldErrors(local);
      return;
    }
    final CompanySettings? saved =
        await ref.read(settingsUpdateControllerProvider.notifier).save(
              CompanySettingsPatch(
                workStartTime: _start,
                workEndTime: _end,
                gracePeriodMinutes: grace,
                minimumWorkingMinutes: minimum,
                overtimeEnabled: _overtime,
                workingDays: SettingsValidation.normalizeWorkingDays(_days),
              ),
            );
    if (!mounted) {
      return;
    }
    if (saved != null) {
      setState(() {
        _hydrate(saved);
        _hydrated = true;
      });
      context.showSnack('Attendance settings saved.');
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
    final ThemeData theme = Theme.of(context);

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
        appBar: AppBar(title: const Text('Attendance')),
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
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _TimeField(
                        label: 'Work start time',
                        value: _start,
                        enabled: canEdit && !update.isSubmitting,
                        errorText: errors['work_start_time'],
                        onTap: () => _pickTime(start: true),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _TimeField(
                        label: 'Work end time',
                        value: _end,
                        enabled: canEdit && !update.isSubmitting,
                        errorText: errors['work_end_time'],
                        onTap: () => _pickTime(start: false),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _grace,
                        label: 'Grace period (minutes)',
                        enabled: canEdit && !update.isSubmitting,
                        keyboardType: TextInputType.number,
                        errorText: errors['grace_period_minutes'],
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _minimum,
                        label: 'Minimum working minutes',
                        enabled: canEdit && !update.isSubmitting,
                        keyboardType: TextInputType.number,
                        errorText: errors['minimum_working_minutes'],
                        onChanged: (_) => setState(() {}),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Overtime enabled'),
                        value: _overtime,
                        onChanged: canEdit && !update.isSubmitting
                            ? (bool value) => setState(() => _overtime = value)
                            : null,
                      ),
                      WorkingDaysSelector(
                        selected: _days,
                        enabled: canEdit && !update.isSubmitting,
                        errorText: errors['working_days'],
                        onChanged: (List<String> days) {
                          setState(() => _days = days);
                        },
                      ),
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

bool _sameDays(List<String> a, List<String> b) {
  if (a.length != b.length) {
    return false;
  }
  final Set<String> left = a.map((String d) => d.toLowerCase()).toSet();
  final Set<String> right = b.map((String d) => d.toLowerCase()).toSet();
  return left.containsAll(right) && right.containsAll(left);
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
    this.enabled = true,
    this.errorText,
  });

  final String label;
  final ClockTime value;
  final VoidCallback onTap;
  final bool enabled;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        suffixIcon: const Icon(Icons.schedule_outlined),
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Text(
            value.label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
