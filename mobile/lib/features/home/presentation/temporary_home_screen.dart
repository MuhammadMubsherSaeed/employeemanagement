import 'package:flutter/material.dart';
import 'package:flutter_base/core/config/env_config.dart';
import 'package:flutter_base/core/config/env_config_provider.dart';
import 'package:flutter_base/core/constants/app_constants.dart';
import 'package:flutter_base/core/extensions/context_extensions.dart';
import 'package:flutter_base/core/theme/app_colors.dart';
import 'package:flutter_base/core/theme/theme_mode_controller.dart';
import 'package:flutter_base/core/widgets/app_avatar.dart';
import 'package:flutter_base/core/widgets/app_button.dart';
import 'package:flutter_base/core/widgets/app_card.dart';
import 'package:flutter_base/core/widgets/app_dialog.dart';
import 'package:flutter_base/core/widgets/app_dropdown.dart';
import 'package:flutter_base/core/widgets/app_empty_state.dart';
import 'package:flutter_base/core/widgets/app_status_badge.dart';
import 'package:flutter_base/core/widgets/app_text_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TemporaryHomeScreen extends ConsumerWidget {
  const TemporaryHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EnvConfig env = ref.watch(envConfigProvider);
    final ThemeMode themeMode = ref.watch(themeModeControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: <Widget>[
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: () => ref.read(themeModeControllerProvider.notifier).cycle(),
            icon: Icon(_themeIcon(themeMode)),
          ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.screen,
        children: <Widget>[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Foundation', style: context.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Temporary home used to verify GoRouter, theme, and shared widgets.',
                  style: context.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: <Widget>[
                    AppStatusBadge(label: env.flavor.name, tone: AppBadgeTone.info),
                    const AppStatusBadge(label: 'Ready', tone: AppBadgeTone.success),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'API: ${env.apiBaseUrl}',
                  style: context.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const AppCard(
            child: Row(
              children: <Widget>[
                AppAvatar(name: 'Alex Morgan'),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text('Reusable widgets are wired and ready for features.'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const AppTextField(
            label: 'Sample field',
            hint: 'Type to confirm the field theme',
          ),
          const SizedBox(height: AppSpacing.md),
          AppDropdown<String>(
            label: 'Sample dropdown',
            value: 'one',
            items: const <AppDropdownItem<String>>[
              AppDropdownItem<String>(value: 'one', label: 'Option one'),
              AppDropdownItem<String>(value: 'two', label: 'Option two'),
            ],
            onChanged: (_) {},
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Show dialog',
            onPressed: () {
              AppDialog.alert(
                context: context,
                title: 'Navigation OK',
                message: 'GoRouter and the widget kit are working.',
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          const AppEmptyState(
            title: 'No business data yet',
            subtitle: 'Auth and HR modules will land in later phases.',
          ),
        ],
      ),
    );
  }

  IconData _themeIcon(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
      ThemeMode.system => Icons.brightness_auto_outlined,
    };
  }
}
