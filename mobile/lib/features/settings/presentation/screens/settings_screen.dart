import 'package:flutter/material.dart';
import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_card.dart';
import 'package:flutter_base/core/auth/authorization_providers.dart';
import 'package:flutter_base/features/settings/domain/settings_access.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SettingsAccess access = SettingsAccess(
      ref.watch(authorizationProvider),
    );
    final TextTheme text = Theme.of(context).textTheme;
    final String subtitle = access.canEdit
        ? 'View and update company configuration.'
        : 'View company configuration.';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: AppSpacing.screen,
        children: <Widget>[
          Text(subtitle, style: text.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            onTap: () => context.push(AppRoutes.settingsCompany),
            child: Row(
              children: <Widget>[
                const Icon(Icons.apartment_outlined),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Company', style: text.titleMedium),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Name, logo, and timezone.',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            onTap: () => context.push(AppRoutes.settingsAttendance),
            child: Row(
              children: <Widget>[
                const Icon(Icons.schedule_outlined),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Attendance', style: text.titleMedium),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Work hours, grace period, and working days.',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
